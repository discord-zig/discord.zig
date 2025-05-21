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

var session: *Discord.Session = undefined;

fn ready(_: *Shard, payload: Discord.Ready) !void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(_: *Shard, message: Discord.Message) !void {
    if (message.content != null) {
        if (std.ascii.eqlIgnoreCase(message.content.?, "!hi")) {
            var result = try session.api.sendMessage(message.channel_id, .{ .content = "hi :)" });
            defer result.deinit();

            const m = result.value.unwrap();
            std.debug.print("sent: {?s}\n", .{m.content});
        }

        if (std.ascii.eqlIgnoreCase(message.content.?, "!ping")) {
            var result = try session.api.sendMessage(message.channel_id, .{ .content = "pong" });
            defer result.deinit();
            const m = result.value.unwrap();
            std.debug.print("sent: {?s}\n", .{m.content});
        }

        if (std.ascii.eqlIgnoreCase(message.content.?, "!create-channel")) {
            var result = try session.api.createChannel(message.guild_id.?, .{
                .name = "test-channel",
                .type = .GuildText,
                .topic = null,
                .bitrate = null,
                .permission_overwrites = null,
                .nsfw = false,
                .default_reaction_emoji = null,
                .available_tags = null,
            });
            defer result.deinit();
            switch (result.value) {
                .left => |err| {
                    std.debug.print("error creating channel: {any}\n", .{err});
                },
                .right => |channel| {
                    std.debug.print("created channel: {?s}\n", .{channel.name});
                },
            }
        }
    }
}

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const allocator = gpa.allocator();

    session = try allocator.create(Discord.Session);
    session.* = Discord.init(allocator);
    defer session.deinit();

    const env_map = try allocator.create(std.process.EnvMap);
    env_map.* = try std.process.getEnvMap(allocator);
    defer env_map.deinit();

    const token = env_map.get("DISCORD_TOKEN") orelse {
        @panic("DISCORD_TOKEN not found in environment variables");
    };

    const intents = comptime blk: {
        var bits: Discord.Intents = .{};
        bits.Guilds = true;
        bits.GuildMessages = true;
        bits.GuildMembers = true;
        // WARNING:
        // YOU MUST SET THIS ON DEV PORTAL
        // OTHERWISE THE LIBRARY WILL CRASH
        bits.MessageContent = true;
        break :blk bits;
    };

    try session.start(.{
        .intents = intents,
        .authorization = token,
        .run = .{ .message_create = &message_create, .ready = &ready },
        .log = .yes,
        .options = .{},
        .cache = .defaults(allocator),
    });
}
