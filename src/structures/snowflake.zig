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

/// Milliseconds since Discord Epoch, the first second of 2015 or 1420070400000.
pub const discord_epoch = 1420070400000;

/// Discord utilizes Twitter's snowflake format for uniquely identifiable descriptors (IDs).
/// These IDs are guaranteed to be unique across all of Discord, except in some unique scenarios in which child objects share their parent's ID.
/// Because Snowflake IDs are up to 64 bits in size (e.g. a uint64), they are always returned as strings in the HTTP API to prevent integer overflows in some languages.
/// See Gateway ETF/JSON for more information regarding Gateway encoding.
pub const Snowflake = enum(u64) {
    _,

    pub fn into(self: Snowflake) u64 {
        return @intFromEnum(self);
    }

    pub fn from(int: u64) Snowflake {
        return @enumFromInt(int);
    }

    pub fn fromMaybe(raw: ?[]const u8) std.fmt.ParseIntError!?Snowflake {
        if (raw) |id| return @enumFromInt(try std.fmt.parseInt(u64, id, 10));
        return null;
    }

    pub fn fromRaw(raw: []const u8) std.fmt.ParseIntError!Snowflake {
        return @enumFromInt(try std.fmt.parseInt(u64, raw, 10));
    }

    pub fn fromMany(allocator: std.mem.Allocator, many: [][]const u8) ![]Snowflake {
        var array = std.ArrayList(Snowflake).init(allocator);

        for (many) |id|
            try array.append(try Snowflake.fromRaw(id));

        return array.toOwnedSlice();
    }

    /// zjson parse
    /// legacy
    pub fn json(_: std.mem.Allocator) void {
        @compileError("Deprecated, use std.json instead.");
    }

    /// std.json parse
    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });

        if (value == .string)
            return Snowflake.fromRaw(value.string) catch
                std.debug.panic("invalid snowflake: {s}\n", .{value.string});
        unreachable;
    }

    /// print
    pub fn format(self: Snowflake, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try writer.print("{d}", .{self.into()});
    }

    /// std.json stringify
    pub fn jsonStringify(snowflake: Snowflake, writer: anytype) !void {
        try writer.print("\"{d}\"", .{snowflake.into()});
    }

    pub inline fn toTimestamp(self: Snowflake) u64 {
        return (self.into() >> 22) + discord_epoch;
    }

    /// Calculate and return the shard ID for a given guild ID
    pub inline fn calculateShardId(self: Snowflake, shards: ?usize) u64 {
        return (self.into() >> 22) % shards orelse 1;
    }
};
