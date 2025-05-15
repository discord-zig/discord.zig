# Discord.zig

A high-performance bleeding edge Discord library in Zig, featuring full API coverage, sharding support, and fine-tuned parsing
* Sharding Support: Ideal for large bots, enabling distributed load handling.
* 100% API Coverage & Fully Typed: Offers complete access to Discord's API with strict typing for reliable and safe code.
* High Performance: Faster than whichever library you can name (WIP)
* Flexible Payload Parsing: Supports payload parsing through both zlib and zstd*.
* Proper error handling

```zig
const std = @import("std");
const Discord = @import("discord");
const Shard = Discord.Shard;

var session: *Discord.Session = undefined;

fn ready(_: *Shard, payload: Discord.Ready) !void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(_: *Shard, message: Discord.Message) !void {
    if (message.content != null and std.ascii.eqlIgnoreCase(message.content.?, "!hi")) {
        var result = try session.api.sendMessage(message.channel_id, .{ .content = "hi :)" });
        defer result.deinit();

        const m = result.value.unwrap();
        std.debug.print("sent: {?s}\n", .{m.content});
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
```

## Installation
```zig
// In your build.zig file
const exe = b.addExecutable(.{
    .name = "marin",
    .root_source_file = b.path("src/main.zig"),
    .target = target,
    .optimize = optimize,
});

const dzig = b.dependency("discord.zig", .{});

exe.root_module.addImport("discord.zig", dzig.module("discord.zig"));
```

**Warning**: the library is intended to be used with the latest dev version of Zig.

## contributing
Contributions are welcome! Please open an issue or pull request if you'd like to help improve the library.
* Support server: https://discord.gg/RBHkBt7nP5
* The original repo: https://codeberg.org/yuzu/discord.zig

## general roadmap
| Task                                                        | Status |
|-------------------------------------------------------------|--------|
| stablish good sharding support w buckets and worker threads | ✅     |
| finish multi threading                                      | ✅     |
| finish the event coverage roadmap                           | ✅     |
| proper error handling                                       | ✅     |
| make the library scalable with a gateway proxy              | ❌     |
| get a cool logo                                             | ❌     |

## missing events right now
| Event                                  | Support |
|----------------------------------------|---------|
| voice_channel_effect_send              | ❌      |
| voice_state_update                     | ❌      |
| voice_server_update                    | ❌      |

## http methods missing
| Endpoint                               | Support |
|----------------------------------------|---------|
| Audit log                              | ❌      |
| Automod                                | ❌      |
| Guild Scheduled Event related          | ❌      |
| Guild template related                 | ❌      |
| Soundboard related                     | ❌      |
| Stage Instance related                 | ❌      |
| Subscription related                   | ❌      |
| Voice related                          | ❌      |
| Webhook related                        | ❌      |
