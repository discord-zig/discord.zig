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
        pub fn jsonParse(allocator: std.mem.Allocator, src: []const u8) !@This() {
            const scanner = std.json.Scanner.initCompleteInput(allocator, src);
            defer scanner.deinit();

            var map: std.EnumMap(E, V) = .{};

            if (try scanner.next() != .object_begin)
                return error.InvalidJson;

            while (true) {
                switch (try scanner.peekNextTokenType()) {
                    .object_end => break,
                    .string => {}, // might be a key
                    else => return error.UnexpectedToken,
                }
                const key = try std.json.innerParse(E, allocator, &scanner, .{
                    .max_value_len = 0x100
                });
                const val = try std.json.innerParse(V, allocator, &scanner, .{
                    .max_value_len = 0x100
                });

                if (map.contains(key))
                    return error.DuplicateKey;

                map.put(key, val);
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
        pub fn jsonParse(allocator: std.mem.Allocator, src: []const u8) !@This() {
            const scanner = std.json.Scanner.initCompleteInput(allocator, src);
            defer scanner.deinit();

            if (try scanner.next() != .object_begin)
                return error.CouldntMatchAgainstNonObjectType;

            // extract next value, which should be an object
            // and should have a key "type" or whichever key might be

            const value = try std.json.innerParse(std.json.Value, allocator, &scanner, .{
                .max_value_len = 0x100
            });

            if (value != .object)
                return error.CouldntMatchAgainstNonObjectType;

            const discriminator = value.object.get(key) orelse
                @panic("couldn't find property " ++ key ++ "in raw object");

            var u: U = undefined;

            if (discriminator != .integer)
                return error.CouldntMatchAgainstNonIntegerType;

            const tag: @typeInfo(E).@"enum".tag_type = @intCast(discriminator.integer);

            inline for (@typeInfo(E).@"enum".fields) |field| {
                if (field.value == tag) {
                    const T = comptime std.meta.fields(U)[field.value].type;
                    comptime std.debug.assert(@hasField(T, key));
                    u = @unionInit(U, field.name, try std.json.innerParse(T, allocator, &scanner, .{.max_value_len = 0x100}));
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
        pub fn jsonParse(allocator: std.mem.Allocator, src: []const u8) !@This() {
            const scanner = std.json.Scanner.initCompleteInput(allocator, src);
            defer scanner.deinit();


            const value = try std.json.innerParse(std.json.Value, allocator, &scanner, .{
                .max_value_len = 0x100
            });

            if (value != .object)
                return error.CouldntMatchAgainstNonObjectType;

            errdefer value.object.deinit();
            var iterator = value.object.iterator();

            var map: std.StringHashMapUnmanaged(T) = .init;

            while (iterator.next()) |pair| {
                const k = pair.key_ptr.*;
                const v = pair.value_ptr.*;

                // might leak because std.json is retarded
                // errdefer allocator.free(k);
                // errdefer v.deinit(allocator);
                try map.put(allocator, k, try std.json.parseFromValue(T, allocator, v, .{ .max_value_len =0x100}));
            }

            return .{ .map = map };
        }
    };
}

