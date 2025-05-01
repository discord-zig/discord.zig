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
const Discord = @import("discord");
const Shard = Discord.Shard;
const Intents = Discord.Intents;

const INTENTS = 53608447;
const Cache = Discord.cache.TableTemplate{};

fn ready(_: *anyopaque, payload: Discord.Ready) !void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(shard_ptr: *anyopaque, message: Discord.Message) !void {
    // set custom cache
    const session: *Shard(Cache) = @ptrCast(@alignCast(shard_ptr));

    if (message.content != null and std.ascii.eqlIgnoreCase(message.content.?, "!hi")) {
        var result = try session.sendMessage(message.channel_id, .{ .content = "hi :)" });
        defer result.deinit();

        const m = result.value.unwrap();
        std.debug.print("sent: {?s}\n", .{m.content});
    }
}

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    var handler = Discord.init(allocator);
    defer handler.deinit();

    const env_map = try allocator.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    const token = env_map.get("DISCORD_TOKEN") orelse {
        @panic("DISCORD_TOKEN not found in environment variables");
    };

    try handler.start(.{
        .token = token,
        .intents = Intents.fromRaw(INTENTS),
        .run = .{ .message_create = &message_create, .ready = &ready },
        .log = .yes,
        .options = .{},
        .cache = Cache,
    });
}
