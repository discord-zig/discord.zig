//! ISC License
//!
//! Copyright (c) 2024-2025 Yuzu
//!
//! Permission to use, copy, modify, and/or distribute this software for any
//! purpose with or without fee is hereby granted, provided that the above
//! copyright notice and this permission notice appear in all copies.
//!
//! THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//! REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
//! AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
//! INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
//! LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
//! OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
//! PERFORMANCE OF THIS SOFTWARE.

const std = @import("std");
const json = std.json;

const MAX_VALUE_LEN = 0x1000;

/// a hashmap for key value pairs
/// where every key is an int
///
/// an example would be this
///
/// {
/// ...
///  "integration_types_config": {
///    "0": ...
///    "1": {
///      "oauth2_install_params": {
///        "scopes": ["applications.commands"],
///        "permissions": "0"
///      }
///    }
///  },
///  ...
/// }
/// this would help us map an enum member 0, 1, etc of type E into V
/// very useful stuff
/// internally, an EnumMap
pub fn AssociativeArray(comptime E: type, comptime V: type) type {
    if (@typeInfo(E) != .@"enum")
        @compileError("may only use enums as keys");

    return struct {
        map: std.EnumMap(E, V),
        pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: json.ParseOptions) !@This() {
            var map: std.EnumMap(E, V) = .{};

            const value = try std.json.innerParse(std.json.Value, allocator, src, .{
                .ignore_unknown_fields = true,
                .max_value_len = MAX_VALUE_LEN
            });

            var iterator = value.object.iterator();

            while (iterator.next()) |it| {
                const k = it.key_ptr.*;
                const v = it.value_ptr.*;

                // eg: enum(u8) would be @"enum".tag_type where tag_type is a u8
                const int = std.fmt.parseInt(@typeInfo(E).@"enum".tag_type, k, 10) catch unreachable;

                const val = try std.json.parseFromValueLeaky(V, allocator, v, .{
                    .ignore_unknown_fields = true,
                    .max_value_len = MAX_VALUE_LEN,
                });

                map.put(@enumFromInt(int), val);
            }

            return .{.map = map};
        }
    };
}


/// assumes object.value[key] is of type `E` and the result thereof maps to the tagged union value
/// assumes `key` is a field present in all members of type `U`
/// eg: `type` is a property of type E and E.User maps to a User struct, whereas E.Admin maps to an Admin struct
pub fn DiscriminatedUnion(comptime U: type, comptime key: []const u8) type {
    if (@typeInfo(U) != .@"union")
        @compileError("may only cast a union");

    if (@typeInfo(U).@"union".tag_type == null)
        @compileError("cannot cast untagged union");

    const E = comptime @typeInfo(U).@"union".tag_type.?;

    if (@typeInfo(U).@"union".tag_type.? != E)
        @compileError("enum tag type of union(" ++ @typeName(U.@"union".tag_type) ++ ") doesn't match " ++ @typeName(E));

    return struct {
        t: U,
        pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: json.ParseOptions) !@This() {
            // extract next value, which should be an object
            // and should have a key "type" or whichever key might be

            const value = try std.json.innerParse(std.json.Value, allocator, src, .{
                .ignore_unknown_fields = true,
                .max_value_len = MAX_VALUE_LEN
            });

            const discriminator = value.object.get(key) orelse
                @panic("couldn't find property " ++ key ++ "in raw object");

            var u: U = undefined;

            const tag: @typeInfo(E).@"enum".tag_type = @intCast(discriminator.integer);

            inline for (@typeInfo(E).@"enum".fields) |field| {
                if (field.value == tag) {
                    const T = comptime std.meta.fields(U)[field.value].type;
                    comptime std.debug.assert(@hasField(T, key));
                    u = @unionInit(U, field.name, try std.json.innerParse(T, allocator, src, .{
                        .ignore_unknown_fields = true,
                        .max_value_len = MAX_VALUE_LEN,
                    }));
                }
            }

            return .{ .t = u };
        }
    };
}

/// a hashmap for key value pairs
pub fn Record(comptime T: type) type {
    return struct {
        map: std.StringHashMapUnmanaged(T),
        pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: json.ParseOptions) !@This() {
            const value = try std.json.innerParse(std.json.Value, allocator, src, .{
                .ignore_unknown_fields = true,
                .max_value_len = MAX_VALUE_LEN
            });

            errdefer value.object.deinit();
            var iterator = value.object.iterator();

            var map: std.StringHashMapUnmanaged(T) = .init;

            while (iterator.next()) |pair| {
                const k = pair.key_ptr.*;
                const v = pair.value_ptr.*;

                // might leak because std.json is retarded
                // errdefer allocator.free(k);
                // errdefer v.deinit(allocator);
                try map.put(allocator, k, try std.json.parseFromValue(T, allocator, v, .{
                    .ignore_unknown_fields = true,
                    .max_value_len = MAX_VALUE_LEN,
                }));
            }

            return .{ .map = map };
        }
    };
}

/// Either a b = Left a | Right b
pub fn Either(comptime L: type, comptime R: type) type {
    return union(enum) {
        left: L,
        right: R,

        /// always returns .right
        pub fn unwrap(self: @This()) R {
            // discord.zig specifics
            if (@hasField(L, "code") and @hasField(L, "message") and self == .left)
                std.debug.panic("Error: {d}, {s}\n", .{ self.left.code, self.left.message });

            // for other libraries, it'll do this
            if (self == .left)
                std.debug.panic("Error: {any}\n", .{self.left});

            return self.right;
        }

        pub fn is(self: @This(), tag: std.meta.Tag(@This())) bool {
            return self == tag;
        }
    };
}


/// meant to handle a `std.json.Value` and handling the deinitialization thereof
pub fn Owned(comptime T: type) type {
    return struct {
        arena: *std.heap.ArenaAllocator,
        value: T,

        pub fn deinit(self: @This()) void {
            const allocator = self.arena.child_allocator;
            self.arena.deinit();
            allocator.destroy(self.arena);
        }
    };
}

/// same as `Owned` but instead it handles 2 different values, generally `.right` is the correct one and `left` the error type
pub fn OwnedEither(comptime L: type, comptime R: type) type {
    return struct {
        value: Either(L, R),
        arena: *std.heap.ArenaAllocator,

        pub fn ok(ok_value: R) @This() {
            return .{ .value = ok_value };
        }

        pub fn err(err_value: L) @This() {
            return .{ .value = err_value };
        }

        pub fn deinit(self: @This()) void {
            const allocator = self.arena.child_allocator;
            self.arena.deinit();
            allocator.destroy(self.arena);
        }
    };
}

/// same as `std.json.parseFromSlice`
pub fn parseRight(comptime L: type, comptime R: type, child_allocator: std.mem.Allocator, data: []const u8) json.ParseError(json.Scanner)!OwnedEither(L, R) {
    var owned: OwnedEither(L, R) = .{
        .arena = try child_allocator.create(std.heap.ArenaAllocator),
        .value = undefined,
    };
    owned.arena.* = .init(child_allocator);
    const allocator = owned.arena.allocator();
    const value = try json.parseFromSliceLeaky(json.Value, allocator, data, .{
        .ignore_unknown_fields = true,
        .max_value_len = MAX_VALUE_LEN,
    });

    owned.value = .{ .right = try json.parseFromValueLeaky(R, allocator, value, .{
        .ignore_unknown_fields = true,
        .max_value_len = MAX_VALUE_LEN,
    }) };
    errdefer owned.arena.deinit();

    return owned;
}


/// same as `std.json.parseFromSlice`
pub fn parseLeft(comptime L: type, comptime R: type, child_allocator: std.mem.Allocator, data: []const u8) json.ParseError(json.Scanner)!OwnedEither(L, R) {
    var owned: OwnedEither(L, R) = .{
        .arena = try child_allocator.create(std.heap.ArenaAllocator),
        .value = undefined,
    };
    owned.arena.* = .init(child_allocator);
    const allocator = owned.arena.allocator();
    const value = try json.parseFromSliceLeaky(json.Value, allocator, data, .{
        .ignore_unknown_fields = true,
        .max_value_len = MAX_VALUE_LEN,
    });

    owned.value = .{ .left = try json.parseFromValueLeaky(L, allocator, value, .{
        .ignore_unknown_fields = true,
        .max_value_len = MAX_VALUE_LEN,
    }) };
    errdefer owned.arena.deinit();

    return owned;
}


