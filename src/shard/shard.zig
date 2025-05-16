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

const ws = @import("ws");
const builtin = @import("builtin");

const std = @import("std");
const net = std.net;
const crypto = std.crypto;
const tls = std.crypto.tls;
const mem = std.mem;
const http = std.http;

// todo use this to read compressed messages
const zlib = @import("zlib");
const json = @import("std").json;

const IdentifyProperties = @import("util.zig").IdentifyProperties;
const GatewayInfo = @import("util.zig").GatewayInfo;
const GatewayBotInfo = @import("util.zig").GatewayBotInfo;
const GatewaySessionStartLimit = @import("util.zig").GatewaySessionStartLimit;
const ShardDetails = @import("util.zig").ShardDetails;
const internalLogif = @import("../utils/core.zig").logif;

const Log = @import("../utils/core.zig").Log;
const GatewayDispatchEvent = @import("../utils/core.zig").GatewayDispatchEvent;
const Bucket = @import("bucket.zig").Bucket;
const default_identify_properties = @import("util.zig").default_identify_properties;

const Types = @import("../structures/types.zig");
const Opcode = Types.GatewayOpcodes;
const Intents = @import("intents.zig").Intents;

const Partial = Types.Partial;

pub const ShardSocketCloseCodes = enum(u16) {
    Shutdown = 3000,
    ZombiedConnection = 3010,
};

const Heart = struct {
    /// interval to send heartbeats, further multiply it with the jitter
    heartbeatInterval: u64,
    /// useful for calculating ping and resuming
    lastBeat: i64,
};

const RatelimitOptions = struct {
    max_requests_per_ratelimit_tick: ?usize = 120,
    ratelimit_reset_interval: u64 = 60000,
};

pub const ShardOptions = struct {
    info: GatewayBotInfo,
    ratelimit_options: RatelimitOptions = .{},
};

const Self = @This();

total_shards: usize,
id: usize,

client: ws.Client,
details: ShardDetails,

//heart: Heart =
allocator: mem.Allocator,
resume_gateway_url: ?[]const u8 = null,
bucket: Bucket,
options: ShardOptions,

session_id: ?[]const u8,
sequence: std.atomic.Value(isize) = .init(0),
heart: Heart = .{ .heartbeatInterval = 45000, .lastBeat = 0 },

// we only need to know whether this shard is part of a thread pool, and if so, initialise it with a pointer thereon
sharder_pool: ?*std.Thread.Pool = null,
handler: GatewayDispatchEvent,
packets: std.ArrayListUnmanaged(u8),
inflator: zlib.Decompressor,

///useful for closing the conn
ws_mutex: std.Thread.Mutex = .{},
rw_mutex: std.Thread.RwLock = .{},
log: Log = .no,

pub fn resumable(self: *Self) bool {
    return self.resume_gateway_url != null and
        self.session_id != null and
        self.sequence.load(.monotonic) > 0;
}

pub fn resume_(self: *Self) SendError!void {
    const data = .{ .op = @intFromEnum(Opcode.Resume), .d = .{
        .token = self.details.token,
        .session_id = self.session_id,
        .seq = self.sequence.load(.monotonic),
    } };

    try self.send(false, data);
}

inline fn gatewayUrl(self: ?*Self) []const u8 {
    return if (self) |s| (s.resume_gateway_url orelse s.options.info.url)["wss://".len..] else "gateway.discord.gg";
}

/// identifies in order to connect to Discord and get the online status, this shall be done on hello perhaps
pub fn identify(self: *Self, properties: ?IdentifyProperties) SendError!void {
    if (self.details.intents.toRaw() != 0) {
        const data = .{
            .op = @intFromEnum(Opcode.Identify),
            .d = .{
                .intents = self.details.intents.toRaw(),
                .properties = properties orelse default_identify_properties,
                .token = self.details.token,
                .shard = &.{ self.id, self.total_shards },
            },
        };
        try self.send(false, data);
    } else {
        const data = .{
            .op = @intFromEnum(Opcode.Identify),
            .d = .{
                .capabilities = 30717,
                .properties = properties orelse default_identify_properties,
                .token = self.details.token,
            },
        };
        try self.send(false, data);
    }
}

pub fn init(allocator: mem.Allocator, shard_id: usize, total_shards: usize, settings: struct {
    token: []const u8,
    intents: Intents,
    options: ShardOptions,
    run: GatewayDispatchEvent,
    log: Log,
    sharder_pool: ?*std.Thread.Pool = null,
}) zlib.Error!Self {
    return Self{
        .options = ShardOptions{
            .info = GatewayBotInfo{
                .url = settings.options.info.url,
                .shards = settings.options.info.shards,
                .session_start_limit = settings.options.info.session_start_limit,
            },
            .ratelimit_options = settings.options.ratelimit_options,
        },
        .id = shard_id,
        .total_shards = total_shards,
        .allocator = allocator,
        .details = ShardDetails{
            .token = settings.token,
            .intents = settings.intents,
        },
        .client = undefined,
        // maybe there is a better way to do this
        .session_id = undefined,
        .handler = settings.run,
        .log = settings.log,
        .packets = .{},
        .inflator = try zlib.Decompressor.init(allocator, .{ .header = .zlib_or_gzip }),
        .bucket = Bucket.init(
            allocator,
            Self.calculateSafeRequests(settings.options.ratelimit_options),
            settings.options.ratelimit_options.ratelimit_reset_interval,
            Self.calculateSafeRequests(settings.options.ratelimit_options),
        ),
        .sharder_pool = settings.sharder_pool,
    };
}

inline fn calculateSafeRequests(options: RatelimitOptions) usize {
    const safe_requests =
        @as(f64, @floatFromInt(options.max_requests_per_ratelimit_tick orelse 120)) -
        @ceil(@as(f64, @floatFromInt(options.ratelimit_reset_interval)) / 30000.0) * 2;

    return if (safe_requests < 0) 0 else @intFromFloat(safe_requests);
}

inline fn _connect_ws(allocator: mem.Allocator, url: []const u8) !ws.Client {
    var conn = try ws.Client.init(allocator, .{
        .tls = true, // important: zig.http doesn't support this, type shit
        .port = 443,
        .host = url,
    });

    var buf: [0x1000]u8 = undefined;
    const host = try std.fmt.bufPrint(&buf, "host: {s}", .{url});

    conn.handshake("/?v=10&encoding=json&compress=zlib-stream", .{
        .timeout_ms = 1000,
        .headers = host,
    }) catch unreachable;

    return conn;
}

pub fn deinit(self: *Self) void {
    self.client.deinit();
}

const ReadMessageError = mem.Allocator.Error || zlib.Error || json.ParseError(json.Scanner);

/// listens for messages
fn readMessage(self: *Self, _: anytype) !void {
    try self.client.readTimeout(0);

    while (try self.client.read()) |msg| { // check your intents, dumbass
        defer self.client.done(msg);

        try self.packets.appendSlice(self.allocator, msg.data);

        // end of zlib
        if (!std.mem.endsWith(u8, msg.data, &[4]u8{ 0x00, 0x00, 0xFF, 0xFF }))
            continue;

        const buf = try self.packets.toOwnedSlice(self.allocator);
        const decompressed = try self.inflator.decompressAllAlloc(buf);
        defer self.allocator.free(decompressed);

        // std.debug.print("Decompressed: {s}\n", .{decompressed});

        std.debug.assert(std.json.validate(self.allocator, decompressed) catch
            @panic("Invalid JSON"));

        // for some reason std.json breaks when you use a generic
        const GatewayPayloadType = struct {
            /// opcode for the payload
            op: isize,
            /// Event data
            d: ?std.json.Value = null,
            /// Sequence isize, used for resuming sessions and heartbeats
            s: ?isize = null,
            /// The event name for this payload
            t: ?[]const u8 = null,
        };

        // must allocate to avoid race conditions
        const payload = try self.allocator.create(std.json.Value);

        // needed for diagnostics
        var scanner = json.Scanner.initCompleteInput(self.allocator, decompressed);
        errdefer scanner.deinit();

        const raw = try std.json.parseFromTokenSource(GatewayPayloadType, self.allocator, &scanner, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        errdefer raw.deinit();

        // make sure to avoid race conditions
        // we free this payload eventually once our event executes
        if (raw.value.d) |p| payload.* = p;

        switch (@as(Opcode, @enumFromInt(raw.value.op))) {
            .Dispatch => {
                if (raw.value.t) |some_name| {
                    self.sequence.store(raw.value.s orelse 0, .monotonic);

                    const name = try self.allocator.alloc(u8, some_name.len);
                    std.mem.copyForwards(u8, name, some_name);

                    // run thread pool
                    if (self.sharder_pool) |sharder_pool| {
                        try sharder_pool.spawn(handleEventNoError, .{ self, name, payload, &scanner });
                    } else try self.handleEvent(name, payload.*);
                }
            },
            .Hello => {
                const HelloPayload = struct { heartbeat_interval: u64, _trace: [][]const u8 };
                const parsed = try std.json.parseFromValue(HelloPayload, self.allocator, payload.*, .{});
                defer parsed.deinit();

                const helloPayload = parsed.value;

                // PARSE NEW URL IN READY

                self.heart = Heart{
                    .heartbeatInterval = helloPayload.heartbeat_interval,
                    .lastBeat = 0,
                };

                if (self.resumable()) {
                    try self.resume_();
                    return;
                }

                try self.identify(self.details.properties);

                var prng = std.Random.DefaultPrng.init(0);
                const jitter = std.Random.float(prng.random(), f64);
                self.heart.lastBeat = std.time.milliTimestamp();
                const heartbeat_writer = try std.Thread.spawn(.{}, heartbeat, .{ self, jitter });
                heartbeat_writer.detach();
            },
            .HeartbeatACK => {
                // perhaps this needs a mutex?
                self.rw_mutex.lock();
                defer self.rw_mutex.unlock();
                self.heart.lastBeat = std.time.milliTimestamp();
            },
            .Heartbeat => {
                self.ws_mutex.lock();
                defer self.ws_mutex.unlock();
                try self.send(false, .{ .op = @intFromEnum(Opcode.Heartbeat), .d = self.sequence.load(.monotonic) });
            },
            .Reconnect => {
                try self.reconnect();
            },
            .Resume => {
                const WithSequence = struct {
                    token: []const u8,
                    session_id: []const u8,
                    seq: ?isize,
                };
                const parsed = try std.json.parseFromValue(WithSequence, self.allocator, payload.*, .{});
                defer parsed.deinit();

                const resume_payload = parsed.value;

                self.sequence.store(resume_payload.seq orelse 0, .monotonic);
                self.session_id = resume_payload.session_id;
            },
            .InvalidSession => {},
            else => {},
        }
    }
}

pub const SendHeartbeatError = CloseError || SendError;

pub fn heartbeat(self: *Self, initial_jitter: f64) SendHeartbeatError!void {
    var jitter = initial_jitter;

    while (true) {
        // basecase
        if (jitter == 1.0) {
            std.Thread.sleep(std.time.ns_per_ms * self.heart.heartbeatInterval);
        } else {
            const timeout = @as(f64, @floatFromInt(self.heart.heartbeatInterval)) * jitter;
            std.Thread.sleep(std.time.ns_per_ms * @as(u64, @intFromFloat(timeout)));
        }

        self.rw_mutex.lock();
        const last = self.heart.lastBeat;
        self.rw_mutex.unlock();

        const seq = self.sequence.load(.monotonic);
        self.ws_mutex.lock();
        try self.send(false, .{ .op = @intFromEnum(Opcode.Heartbeat), .d = seq });
        self.ws_mutex.unlock();

        if ((std.time.milliTimestamp() - last) > (5000 * self.heart.heartbeatInterval)) {
            try self.close(ShardSocketCloseCodes.ZombiedConnection, "Zombied connection");
            @panic("zombied conn\n");
        }

        jitter = 1.0;
    }
}

pub const ReconnectError = ConnectError || CloseError;

pub fn reconnect(self: *Self) ReconnectError!void {
    try self.disconnect();
    try self.connect();
}

pub const ConnectError =
    net.TcpConnectToAddressError || crypto.tls.Client.InitError(net.Stream) ||
    net.Stream.ReadError || net.IPParseError ||
    crypto.Certificate.Bundle.RescanError || net.TcpConnectToHostError ||
    std.fmt.BufPrintError || mem.Allocator.Error;

pub fn connect(self: *Self) ConnectError!void {
    //std.time.sleep(std.time.ms_per_s * 5);
    self.client = try Self._connect_ws(self.allocator, self.gatewayUrl());

    self.readMessage(null) catch |err| switch (err) {
        // weird Windows error
        // https://github.com/ziglang/zig/issues/21492
        std.net.Stream.ReadError.NotOpenForReading, error.Closed => {
            std.debug.panic("Shard {d}: Stream closed unexpectedly", .{self.id}); // still check your intents
        },
        else => {
            // log that the connection died, but don't stop the bot
            self.logif("Shard {d} closed with error: {s}\n", .{self.id, @errorName(err)});
            self.logif("Attempting to reconnect...\n", .{});
            // reconnect
            self.reconnect() catch unreachable;
        }
    };
}

pub fn disconnect(self: *Self) CloseError!void {
    try self.close(ShardSocketCloseCodes.Shutdown, "Shard down request");
}

pub const CloseError = mem.Allocator.Error || error{ReasonTooLong};

pub fn close(self: *Self, code: ShardSocketCloseCodes, reason: []const u8) CloseError!void {
    // Implement reconnection logic here
    self.client.close(.{
        .code = @intFromEnum(code), //u16
        .reason = reason, //[]const u8
    }) catch {
        // log that the connection died, but don't stop the bot
        self.logif("Shard {d} closed with error: {s} # {d}\n", .{self.id, reason, @intFromEnum(code)});
    };
}

pub const SendError = net.Stream.WriteError || std.ArrayList(u8).Writer.Error;

pub fn send(self: *Self, _: bool, data: anytype) SendError!void {
    var buf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(data, .{}, string.writer());

    try self.client.write(try string.toOwnedSlice());
}

pub fn handleEventNoError(self: *Self, name: []const u8, payload_ptr: *json.Value, scanner: *json.Scanner) void {
    var diagnostics = json.Diagnostics{};
    scanner.enableDiagnostics(&diagnostics);

    // log to make sure this executes
    self.logif("Shard {d} dispatching {s}", .{self.id, name});

    const stdout = std.io.getStdOut().writer();

    self.handleEvent(name, payload_ptr.*) catch |err| {
        self.logif(
            \\Shard {d} error: {s}
            \\on column {d} and line {d} offset {d}
        , .{
            self.id,
            @errorName(err),
            diagnostics.getColumn(),
            diagnostics.getLine(),
            diagnostics.getByteOffset(),
        });
        std.json.stringify(payload_ptr, .{
            .whitespace = .indent_4
        }, stdout) catch {};
    };
}

pub fn handleEvent(self: *Self, name: []const u8, payload: json.Value) !void {
    if (mem.eql(u8, name, "READY")) if (self.handler.ready) |event| {
        const ready = try json.parseFromValue(Types.Ready, self.allocator, payload, .{
            .ignore_unknown_fields=true,
            .max_value_len=0x1000,
        });

        try event(self, ready.value);
    };

    if (mem.eql(u8, name, "APPLICATION_COMMAND_PERMISSIONS_UPDATE")) if (self.handler.application_command_permissions_update) |event| {
        const acp = try json.parseFromValue(Types.ApplicationCommandPermissions, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, acp.value);
    };

    if (mem.eql(u8, name, "CHANNEL_CREATE")) if (self.handler.channel_create) |event| {
        const chan = try json.parseFromValue(Types.Channel, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, chan.value);
    };

    if (mem.eql(u8, name, "CHANNEL_UPDATE")) if (self.handler.channel_update) |event| {
        const chan = try json.parseFromValue(Types.Channel, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, chan.value);
    };

    if (mem.eql(u8, name, "CHANNEL_DELETE")) if (self.handler.channel_delete) |event| {
        const chan = try json.parseFromValue(Types.Channel, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, chan.value);
    };

    if (mem.eql(u8, name, "CHANNEL_PINS_UPDATE")) if (self.handler.channel_pins_update) |event| {
        const chan_pins_update = try json.parseFromValue(Types.ChannelPinsUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, chan_pins_update.value);
    };

    if (mem.eql(u8, name, "ENTITLEMENT_CREATE")) if (self.handler.entitlement_create) |event| {
        const entitlement = try json.parseFromValue(Types.Entitlement, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, entitlement.value);
    };

    if (mem.eql(u8, name, "ENTITLEMENT_UPDATE")) if (self.handler.entitlement_update) |event| {
        const entitlement = try json.parseFromValue(Types.Entitlement, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, entitlement.value);
    };

    if (mem.eql(u8, name, "ENTITLEMENT_DELETE")) if (self.handler.entitlement_delete) |event| {
        const entitlement = try json.parseFromValue(Types.Entitlement, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, entitlement.value);
    };

    if (mem.eql(u8, name, "INTEGRATION_CREATE")) if (self.handler.integration_create) |event| {
        const guild_id = try json.parseFromValue(Types.IntegrationCreateUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, guild_id.value);
    };

    if (mem.eql(u8, name, "INTEGRATION_UPDATE")) if (self.handler.integration_update) |event| {
        const guild_id = try json.parseFromValue(Types.IntegrationCreateUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, guild_id.value);
    };

    if (mem.eql(u8, name, "INTEGRATION_DELETE")) if (self.handler.integration_delete) |event| {
        const data = try json.parseFromValue(Types.IntegrationDelete, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "INTERACTION_CREATE")) if (self.handler.interaction_create) |event| {
        const interaction = try json.parseFromValue(Types.MessageInteraction, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, interaction.value);
    };

    if (mem.eql(u8, name, "INVITE_CREATE")) if (self.handler.invite_create) |event| {
        const data = try json.parseFromValue(Types.InviteCreate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "INVITE_DELETE")) if (self.handler.invite_delete) |event| {
        const data = try json.parseFromValue(Types.InviteDelete, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "MESSAGE_CREATE")) if (self.handler.message_create) |event| {
        const message = try json.parseFromValue(Types.Message, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, message.value);
    };

    if (mem.eql(u8, name, "MESSAGE_DELETE")) if (self.handler.message_delete) |event| {
        const data = try json.parseFromValue(Types.MessageDelete, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "MESSAGE_UPDATE")) if (self.handler.message_update) |event| {
        const message = try json.parseFromValue(Types.Message, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, message.value);
    };

    if (mem.eql(u8, name, "MESSAGE_DELETE_BULK")) if (self.handler.message_delete_bulk) |event| {
        const data = try json.parseFromValue(Types.MessageDeleteBulk, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "MESSAGE_REACTION_ADD")) if (self.handler.message_reaction_add) |event| {
        const reaction = try json.parseFromValue(Types.MessageReactionAdd, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, reaction.value);
    };

    if (mem.eql(u8, name, "MESSAGE_REACTION_REMOVE")) if (self.handler.message_reaction_remove) |event| {
        const reaction = try json.parseFromValue(Types.MessageReactionRemove, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, reaction.value);
    };

    if (mem.eql(u8, name, "MESSAGE_REACTION_REMOVE_ALL")) if (self.handler.message_reaction_remove_all) |event| {
        const data = try json.parseFromValue(Types.MessageReactionRemoveAll, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "MESSAGE_REACTION_REMOVE_EMOJI")) if (self.handler.message_reaction_remove_emoji) |event| {
        const emoji = try json.parseFromValue(Types.MessageReactionRemoveEmoji, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, emoji.value);
    };

    if (mem.eql(u8, name, "GUILD_CREATE")) {
        const isAvailable =
            try json.parseFromValue(struct { unavailable: ?bool }, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        if (isAvailable.value.unavailable == true) {
            const guild = try json.parseFromValue(Types.Guild, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

            if (self.handler.guild_create) |event| try event(self, guild.value);
            return;
        }

        const guild = try json.parseFromValue(Types.UnavailableGuild, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        if (self.handler.guild_create_unavailable) |event| try event(self, guild.value);
    }

    if (mem.eql(u8, name, "GUILD_UPDATE")) if (self.handler.guild_update) |event| {
        const guild = try json.parseFromValue(Types.Guild, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, guild.value);
    };

    if (mem.eql(u8, name, "GUILD_DELETE")) if (self.handler.guild_delete) |event| {
        const guild = try json.parseFromValue(Types.UnavailableGuild, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, guild.value);
    };

    if (mem.eql(u8, name, "GUILD_SCHEDULED_EVENT_CREATE")) if (self.handler.guild_scheduled_event_create) |event| {
        const s_event = try json.parseFromValue(Types.ScheduledEvent, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, s_event.value);
    };

    if (mem.eql(u8, name, "GUILD_SCHEDULED_EVENT_UPDATE")) if (self.handler.guild_scheduled_event_update) |event| {
        const s_event = try json.parseFromValue(Types.ScheduledEvent, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, s_event.value);
    };

    if (mem.eql(u8, name, "GUILD_SCHEDULED_EVENT_DELETE")) if (self.handler.guild_scheduled_event_delete) |event| {
        const s_event = try json.parseFromValue(Types.ScheduledEvent, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, s_event.value);
    };

    if (mem.eql(u8, name, "GUILD_SCHEDULED_EVENT_USER_ADD")) if (self.handler.guild_scheduled_event_user_add) |event| {
        const data = try json.parseFromValue(Types.ScheduledEventUserAdd, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "GUILD_SCHEDULED_EVENT_USER_REMOVE")) if (self.handler.guild_scheduled_event_user_remove) |event| {
        const data = try json.parseFromValue(Types.ScheduledEventUserRemove, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "GUILD_MEMBER_ADD")) if (self.handler.guild_member_add) |event| {
        const guild_id = try json.parseFromValue(Types.GuildMemberAdd, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, guild_id.value);
    };

    if (mem.eql(u8, name, "GUILD_MEMBER_UPDATE")) if (self.handler.guild_member_update) |event| {
        const fields = try json.parseFromValue(Types.GuildMemberUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, fields.value);
    };

    if (mem.eql(u8, name, "GUILD_MEMBER_REMOVE")) if (self.handler.guild_member_remove) |event| {
        const user = try json.parseFromValue(Types.GuildMemberRemove, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, user.value);
    };

    if (mem.eql(u8, name, "GUILD_MEMBERS_CHUNK")) if (self.handler.guild_members_chunk) |event| {
        const data = try json.parseFromValue(Types.GuildMembersChunk, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "GUILD_ROLE_CREATE")) if (self.handler.guild_role_create) |event| {
        const role = try json.parseFromValue(Types.GuildRoleCreate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, role.value);
    };

    if (mem.eql(u8, name, "GUILD_ROLE_UPDATE")) if (self.handler.guild_role_update) |event| {
        const role = try json.parseFromValue(Types.GuildRoleUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, role.value);
    };

    if (mem.eql(u8, name, "GUILD_ROLE_DELETE")) if (self.handler.guild_role_delete) |event| {
        const role_id = try json.parseFromValue(Types.GuildRoleDelete, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, role_id.value);
    };

    if (mem.eql(u8, name, "GUILD_DELETE")) if (self.handler.guild_delete) |event| {
        const guild = try json.parseFromValue(Types.UnavailableGuild, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, guild.value);
    };

    if (mem.eql(u8, name, "GUILD_BAN_ADD")) if (self.handler.guild_ban_add) |event| {
        const gba = try json.parseFromValue(Types.GuildBanAddRemove, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, gba.value);
    };

    if (mem.eql(u8, name, "GUILD_BAN_REMOVE")) if (self.handler.guild_ban_remove) |event| {
        const gbr = try json.parseFromValue(Types.GuildBanAddRemove, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, gbr.value);
    };

    if (mem.eql(u8, name, "GUILD_EMOJIS_UPDATE")) if (self.handler.guild_emojis_update) |event| {
        const emojis = try json.parseFromValue(Types.GuildEmojisUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, emojis.value);
    };

    if (mem.eql(u8, name, "GUILD_STICKERS_UPDATE")) if (self.handler.guild_stickers_update) |event| {
        const stickers = try json.parseFromValue(Types.GuildStickersUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, stickers.value);
    };

    if (mem.eql(u8, name, "GUILD_INTEGRATIONS_UPDATE")) if (self.handler.guild_integrations_update) |event| {
        const guild_id = try json.parseFromValue(Types.GuildIntegrationsUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, guild_id.value);
    };

    if (mem.eql(u8, name, "THREAD_CREATE")) if (self.handler.thread_create) |event| {
        const thread = try json.parseFromValue(Types.Channel, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, thread.value);
    };

    if (mem.eql(u8, name, "THREAD_UPDATE")) if (self.handler.thread_update) |event| {
        const thread = try json.parseFromValue(Types.Channel, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, thread.value);
    };

    if (mem.eql(u8, name, "THREAD_DELETE")) if (self.handler.thread_delete) |event| {
        const thread_data = try json.parseFromValue(Types.Partial(Types.Channel), self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, thread_data.value);
    };

    if (mem.eql(u8, name, "THREAD_LIST_SYNC")) if (self.handler.thread_list_sync) |event| {
        const data = try json.parseFromValue(Types.ThreadListSync, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "THREAD_MEMBER_UPDATE")) if (self.handler.thread_member_update) |event| {
        const guild_id = try json.parseFromValue(Types.ThreadMemberUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, guild_id.value);
    };

    if (mem.eql(u8, name, "THREAD_MEMBERS_UPDATE")) if (self.handler.thread_members_update) |event| {
        const data = try json.parseFromValue(Types.ThreadMembersUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "TYPING_START")) if (self.handler.typing_start) |event| {
        const data = try json.parseFromValue(Types.TypingStart, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "USER_UPDATE")) if (self.handler.user_update) |event| {
        const user = try json.parseFromValue(Types.User, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, user.value);
    };

    if (mem.eql(u8, name, "PRESENCE_UPDATE")) if (self.handler.presence_update) |event| {
        const pu = try json.parseFromValue(Types.PresenceUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, pu.value);
    };

    if (mem.eql(u8, name, "MESSSAGE_POLL_VOTE_ADD")) if (self.handler.message_poll_vote_add) |event| {
        const data = try json.parseFromValue(Types.PollVoteAdd, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "MESSSAGE_POLL_VOTE_REMOVE")) if (self.handler.message_poll_vote_remove) |event| {
        const data = try json.parseFromValue(Types.PollVoteRemove, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, data.value);
    };

    if (mem.eql(u8, name, "WEBHOOKS_UPDATE")) if (self.handler.webhooks_update) |event| {
        const fields = try json.parseFromValue(Types.WebhookUpdate, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, fields.value);
    };

    if (mem.eql(u8, name, "STAGE_INSTANCE_CREATE")) if (self.handler.stage_instance_create) |event| {
        const stage = try json.parseFromValue(Types.StageInstance, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, stage.value);
    };

    if (mem.eql(u8, name, "STAGE_INSTANCE_UPDATE")) if (self.handler.stage_instance_update) |event| {
        const stage = try json.parseFromValue(Types.StageInstance, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, stage.value);
    };

    if (mem.eql(u8, name, "STAGE_INSTANCE_DELETE")) if (self.handler.stage_instance_delete) |event| {
        const stage = try json.parseFromValue(Types.StageInstance, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, stage.value);
    };

    if (mem.eql(u8, name, "AUTO_MODERATION_RULE_CREATE")) if (self.handler.auto_moderation_rule_create) |event| {
        const rule = try json.parseFromValue(Types.AutoModerationRule, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, rule.value);
    };

    if (mem.eql(u8, name, "AUTO_MODERATION_RULE_UPDATE")) if (self.handler.auto_moderation_rule_update) |event| {
        const rule = try json.parseFromValue(Types.AutoModerationRule, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, rule.value);
    };

    if (mem.eql(u8, name, "AUTO_MODERATION_RULE_DELETE")) if (self.handler.auto_moderation_rule_delete) |event| {
        const rule = try json.parseFromValue(Types.AutoModerationRule, self.allocator, payload, .{.ignore_unknown_fields=true, .max_value_len=0x1000});

        try event(self, rule.value);
    };

    if (mem.eql(u8, name, "AUTO_MODERATION_ACTION_EXECUTION")) if (self.handler.auto_moderation_action_execution) |event| {
        const ax = try json.parseFromValue(Types.AutoModerationActionExecution, self.allocator, payload, .{ .ignore_unknown_fields=true, .max_value_len = 0x1000,
        });

        try event(self, ax.value);
    };

    // default handler for whoever wants it
    //if (self.handler.any) |anyEvent|
        //try anyEvent(self, payload);
}

pub fn logif(self: *Self, comptime format: []const u8, args: anytype) void {
    internalLogif(self.log, format, args);
}

