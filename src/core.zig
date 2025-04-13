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

const Intents = @import("./structures/types.zig").Intents;
const Snowflake = @import("./structures/snowflake.zig").Snowflake;
const GatewayBotInfo = @import("internal.zig").GatewayBotInfo;
const IdentifyProperties = @import("internal.zig").IdentifyProperties;
const ShardDetails = @import("internal.zig").ShardDetails;
const ConnectQueue = @import("internal.zig").ConnectQueue;
const GatewayDispatchEvent = @import("internal.zig").GatewayDispatchEvent;
const Log = @import("internal.zig").Log;
const Shard = @import("shard.zig");
const std = @import("std");
const mem = std.mem;
const debug = @import("internal.zig").debug;

const Self = @This();

shard_details: ShardDetails,
allocator: mem.Allocator,

/// Queue for managing shard connections
connect_queue: ConnectQueue(Shard),
shards: std.AutoArrayHashMap(usize, Shard),
handler: GatewayDispatchEvent(*Shard),

/// where we dispatch work for every thread, threads must be spawned upon shard creation
/// make sure the address of workers is stable
workers: std.Thread.Pool = undefined,

/// configuration settings
options: SessionOptions,
log: Log,
cache: @import("cache.zig").CacheTables,

pub const ShardData = struct {
    /// resume seq to resume connections
    resume_seq: ?usize,

    /// resume_gateway_url is the url to resume the connection
    /// https://discord.com/developers/docs/topics/gateway#ready-event
    resume_gateway_url: ?[]const u8,

    /// session_id is the unique session id of the gateway
    session_id: ?[]const u8,
};

pub const SessionOptions = struct {
    /// Important data which is used by the manager to connect shards to the gateway. */
    info: GatewayBotInfo,
    /// Delay in milliseconds to wait before spawning next shard. OPTIMAL IS ABOVE 5100. YOU DON'T WANT TO HIT THE RATE LIMIT!!!
    spawn_shard_delay: ?u64 = 5300,
    /// Total amount of shards your bot uses. Useful for zero-downtime updates or resharding.
    total_shards: usize = 1,
    shard_start: usize = 0,
    shard_end: usize = 1,
    /// The payload handlers for messages on the shard.
    resharding: ?struct { interval: u64, percentage: usize } = null,
    /// worker threads
    workers_per_shard: usize = 1,
    /// The shard lifespan in milliseconds. If a shard is not connected within this time, it will be closed.
    shard_lifespan: ?u64 = null,
};

pub fn init(allocator: mem.Allocator, settings: struct {
    token: []const u8,
    intents: Intents,
    options: SessionOptions,
    run: GatewayDispatchEvent(*Shard),
    log: Log,
    cache: @import("cache.zig").CacheTables,
}) mem.Allocator.Error!Self {
    const concurrency = settings.options.info.session_start_limit.?.max_concurrency;
    return .{
        .allocator = allocator,
        .connect_queue = try ConnectQueue(Shard).init(allocator, concurrency, 5000),
        .shards = .init(allocator),
        .workers = undefined,
        .shard_details = ShardDetails{
            .token = settings.token,
            .intents = settings.intents,
        },
        .handler = settings.run,
        .options = .{
            .info = .{
                .url = settings.options.info.url,
                .shards = settings.options.info.shards,
                .session_start_limit = settings.options.info.session_start_limit,
            },
            .total_shards = settings.options.total_shards,
            .shard_start = settings.options.shard_start,
            .shard_end = settings.options.shard_end,
            .workers_per_shard = settings.options.workers_per_shard,
        },
        .log = settings.log,
        .cache = settings.cache,
    };
}

pub fn deinit(self: *Self) void {
    self.connect_queue.deinit();
    self.shards.deinit();
}

pub fn forceIdentify(self: *Self, shard_id: usize) !void {
    self.logif("#{d} force identify", .{shard_id});
    const shard = try self.create(shard_id);

    return shard.identify(null);
}

pub fn disconnect(self: *Self, shard_id: usize) Shard.CloseError!void {
    return if (self.shards.get(shard_id)) |shard| shard.disconnect();
}

pub fn disconnectAll(self: *Self) Shard.CloseError!void {
    while (self.shards.iterator().next()) |shard| shard.value_ptr.disconnect();
}

/// spawn buckets in order
/// Log bucket preparation
/// Divide shards into chunks based on concurrency
/// Assign each shard to a bucket
/// Return list of buckets
/// https://discord.com/developers/docs/events/gateway#sharding-max-concurrency
fn spawnBuckets(self: *Self) ![][]Shard {
    const concurrency = self.options.info.session_start_limit.?.max_concurrency;

    self.logif("{d}-{d}", .{ self.options.shard_start, self.options.shard_end });

    const range = std.math.sub(usize, self.options.shard_start, self.options.shard_end) catch 1;
    const bucket_count = (range + concurrency - 1) / concurrency;

    self.logif("#0 preparing buckets", .{});

    const buckets = try self.allocator.alloc([]Shard, bucket_count);

    for (buckets, 0..) |*bucket, i| {
        const bucket_size = if ((i + 1) * concurrency > range) range - (i * concurrency) else concurrency;

        bucket.* = try self.allocator.alloc(Shard, bucket_size);

        for (bucket.*, 0..) |*shard, j| {
            shard.* = try self.create(self.options.shard_start + i * concurrency + j);
        }
    }

    self.logif("{d} buckets created", .{bucket_count});

    // finally defihne threads

    try self.workers.init(.{
        .allocator = self.allocator,
        .n_jobs = self.options.workers_per_shard * self.options.total_shards,
    });

    return buckets;
}

/// creates a shard and stores it
fn create(self: *Self, shard_id: usize) !Shard {
    if (self.shards.get(shard_id)) |s| return s;

    const shard: Shard = try .init(self.allocator, shard_id, self.options.total_shards, .{
        .token = self.shard_details.token,
        .intents = self.shard_details.intents,
        .options = Shard.ShardOptions{
            .info = self.options.info,
            .ratelimit_options = .{},
        },
        .run = self.handler,
        .log = self.log,
        .cache = self.cache,
        .sharder_pool = &self.workers,
    });

    try self.shards.put(shard_id, shard);

    return shard;
}

pub fn resume_(self: *Self, shard_id: usize, shard_data: ShardData) void {
    if (self.shards.contains(shard_id)) return error.CannotOverrideExistingShard;

    const shard = self.create(shard_id);

    shard.data = shard_data;

    return self.connect_queue.push(.{
        .shard = shard,
        .callback = &callback,
    });
}

fn callback(self: *ConnectQueue(Shard).RequestWithShard) anyerror!void {
    try self.shard.connect();
}

pub fn spawnShards(self: *Self) !void {
    const buckets = try self.spawnBuckets();

    self.logif("Spawning shards", .{});

    for (buckets) |bucket| {
        for (bucket) |shard| {
            self.logif("adding {d} to connect queue", .{shard.id});
            try self.connect_queue.push(.{
                .shard = shard,
                .callback = &callback,
            });
        }
    }

    //self.startResharder();
}

pub fn send(self: *Self, shard_id: usize, data: anytype) Shard.SendError!void {
    if (self.shards.get(shard_id)) |shard| try shard.send(data);
}

// SPEC OF THE RESHARDER:
// Class Self
//
//     Method startResharder():
//         If resharding interval is not set or shard bounds are not valid:
//             Exit
//         Set up periodic check for resharding:
//             If new shards are required:
//                 Log resharding process
//                 Update options with new shard settings
//                 Disconnect old shards and clear them from manager
//                 Spawn shards again with updated configuration
//

inline fn logif(self: *Self, comptime format: []const u8, args: anytype) void {
    switch (self.log) {
        .yes => debug.info(format, args),
        .no => {},
    }
}
