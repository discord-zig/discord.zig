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

fn ready(_: *Shard, payload: Discord.Ready) !void {
    std.debug.print("logged in as {s}\n", .{payload.user.username});
}

fn message_create(session: *Shard, message: Discord.Message) !void {
    if (std.ascii.eqlIgnoreCase(message.content.?, "!hi")) {
        var result = try session.sendMessage(message.channel_id, .{
            .content = "hello world from discord.zig",
        });
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

    try handler.start(.{
        .intents = Discord.Intents.fromRaw(53608447),
        .token = std.posix.getenv("DISCORD_TOKEN").?,
        .run = .{ .message_create = &message_create, .ready = &ready },
        .options = .{},
        .log = .yes,
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

* Support server: <https://discord.gg/RBHkBt7nP5>
* The original repo: <https://codeberg.org/yuzu/discord.zig>

## general roadmap

| Task                                                        | Status |
|-------------------------------------------------------------|--------|
| stablish good sharding support with buckets                 | ✅     |
| finish the event coverage roadmap                           | ✅     |
| proper error handling                                       | ✅     |
| use the priority queues for handling ratelimits (half done) | ❌     |
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
