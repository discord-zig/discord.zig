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

const Result = @import("../errors.zig").Result;

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

const Snowflake = Types.Snowflake;
const FetchReq = @import("../http/http.zig").FetchReq;
const MakeRequestError = @import("../http/http.zig").MakeRequestError;
const Partial = Types.Partial;
const TableTemplate = @import("../cache/cache.zig").TableTemplate;
const CacheTables = @import("../cache/cache.zig").CacheTables;
const FileData = @import("../http/http.zig").FileData;

pub fn Shard(comptime Table: TableTemplate) type {
    return struct {
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

        /// actual cache
        cache_handler: *CacheTables(Table),

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
            cache: *CacheTables(Table),
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
                .cache_handler = settings.cache,
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

                const raw = try std.json.parseFromSlice(GatewayPayloadType, self.allocator, decompressed, .{
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
                                try sharder_pool.spawn(handleEventNoError, .{ self, name, payload });
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

        pub fn handleEventNoError(self: *Self, name: []const u8, payload_ptr: *json.Value) void {
            // log to make sure this executes
            self.logif("Shard {d} dispatching {s}\n", .{self.id, name});

            self.handleEvent(name, payload_ptr.*) catch |err| {
                self.logif("Shard {d} error: {s}\n", .{self.id, @errorName(err)});
            };
        }

        pub fn handleEvent(self: *Self, name: []const u8, payload: json.Value) !void {
            if (mem.eql(u8, name, "READY")) if (self.handler.ready) |event| {
                const ready = try json.parseFromValue(Types.Ready, self.allocator, payload, .{
                    .ignore_unknown_fields=true,
                    .max_value_len=0x1000,
                });

                // store ourselves in

                // TODO: fix this lmao
                //if (std.meta.hasFn(Table.User, "transform")) {
                //    try self.cache_handler.users.put(ready.value.user.id, Table.User.transform(ready.value.user));
                //} else {
                //    @panic("User transform not implemented");
                //}

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

        pub const RequestFailedError = MakeRequestError || error{FailedRequest} || json.ParseError(json.Scanner);

        // start http methods

        /// Retrieves the messages in a channel.
        /// Returns an array of message objects on success.
        /// If operating on a guild channel, this endpoint requires the current user to have the `VIEW_CHANNEL` permission.
        /// If the channel is a voice channel, they must also have the `CONNECT` permission.
        /// If the current user is missing the `READ_MESSAGE_HISTORY` permission in the channel, then no messages will be returned.
        pub fn fetchMessages(self: *Self, channel_id: Snowflake, query: Types.GetMessagesQuery) RequestFailedError!Result([]Types.Message) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addQueryParam("limit", query.limit);
            try req.addQueryParam("around", query.around);
            try req.addQueryParam("before", query.before);
            try req.addQueryParam("after", query.after);

            const messages = try req.get([]Types.Message, path);
            return messages;
        }

        /// Retrieves a specific message in the channel.
        /// Returns a message object on success.
        /// If operating on a guild channel, this endpoint requires the current user to have the `VIEW_CHANNEL` and `READ_MESSAGE_HISTORY` permissions.
        /// If the channel is a voice channel, they must also have the `CONNECT` permission.
        pub fn fetchMessage(self: *Self, channel_id: Snowflake, message_id: Snowflake) RequestFailedError!Result(Types.Message) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}", .{ channel_id.into(), message_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const message = try req.get(Types.Message, path);
            return message;
        }

        /// Post a message to a guild text or DM channel.
        /// Returns a message object.
        /// Fires a Message Create Gateway event.
        /// See message formatting for more information on how to properly format messages.
        /// To create a message as a reply or forward of another message, apps can include a `message_reference`.
        /// Refer to the documentation for required fields.
        ///
        /// example
        /// var msg = try session.sendMessage(message.channel_id, .{
        ///     .content = "discord.zig best library",
        /// });
        /// defer msg.deinit();
        pub fn sendMessage(
            self: *Self,
            channel_id: Snowflake,
            create_message: Partial(Types.CreateMessage),
        ) RequestFailedError!Result(Types.Message) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.post(Types.Message, path, create_message);
            return res;
        }

        /// not part of Discord's docs
        /// wrapper for sending files
        pub const CreateMessageWithFile = struct {
            /// the create message payload
            create_message: Partial(Types.CreateMessage),
            /// the files to send, must be one of FileData.type
            files: []FileData,
        };

        /// same as `sendMessage` but acceps a files field
        /// example:
        ///
        /// var attachments = [_]Discord.Partial(Discord.Attachment){
        ///     .{
        ///         .id = Discord.Snowflake.from(0),
        ///         .description = "my profile picture",
        ///         .filename = "pfp.webp", // must be the same as FileData.filename
        ///     },
        /// };
        ///
        /// var files = [_]Discord.FileData{
        ///     .{
        ///         .type = .webp,
        ///         .filename = "pfp.webp",
        ///         .value = @embedFile("pfp.webp"),
        ///     },
        /// };
        /// const payload: Discord.Partial(Discord.CreateMessage) = .{
        ///     .content = "discord.zig best library",
        ///     .attachments = &attachments,
        /// };
        /// var msg = try session.sendMessageWithFiles(message.channel_id, .{
        ///     .create_message = payload,
        ///     .files = &files,
        /// });
        /// defer msg.deinit();
        pub fn sendMessageWithFiles(
            self: *Self,
            channel_id: Snowflake,
            wf: CreateMessageWithFile,
        ) RequestFailedError!void {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const msg = try req.post3(Types.Message, path, wf.create_message, wf.files);
            return msg;
        }

        /// Crosspost a message in an Announcement Channel to following channels.
        /// This endpoint requires the `SEND_MESSAGES` permission, if the current user sent the message, or additionally the `MANAGE_MESSAGES` permission, for all other messages, to be present for the current user.
        /// Returns a message object.
        /// Fires a Message Update Gateway event.
        pub fn crosspostMessage(self: *Self, channel_id: Snowflake, message_id: Snowflake) RequestFailedError!Result(Types.Message) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}/crosspost", .{ channel_id.into(), message_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.post2(Types.Message, path);
            return res;
        }

        /// Create a reaction for the message.
        /// This endpoint requires the `READ_MESSAGE_HISTORY` permission to be present on the current user.
        /// Additionally, if nobody else has reacted to the message using this emoji, this endpoint requires the `ADD_REACTIONS` permission to be present on the current user.
        /// Returns a 204 empty response on success.
        /// Fires a Message Reaction Add Gateway event.
        pub fn react(
            self: *Self,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: Types.Emoji,
        ) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}/reactions/{s}:{d}/@me", .{
                channel_id.into(),
                message_id.into(),
                emoji.name.?, // formatted as name:id
                emoji.id.?.into(),
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.put3(path);
        }

        /// Delete a reaction the current user has made for the message.
        /// Returns a 204 empty response on success.
        /// Fires a Message Reaction Remove Gateway event.
        pub fn deleteOwnReaction(
            self: *Self,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: Types.Emoji,
        ) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}/reactions/{s}:{d}/@me", .{
                channel_id.into(),
                message_id.into(),
                emoji.name.?, // formatted as name:id
                emoji.id.?.into(),
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        /// Get a list of users that reacted with this emoji.
        /// Returns an array of user objects on success.
        /// TODO: implement query and such
        pub fn fetchReactions(
            self: *Self,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: Types.Emoji,
        ) RequestFailedError!Result([]Types.User) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}/reactions/{s}:{d}", .{
                channel_id.into(),
                message_id.into(),
                emoji.name.?, // formatted as name:id
                emoji.id.?.into(),
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const users = try req.get([]Types.User, path);
            return users;
        }

        /// Deletes all reactions on a message.
        /// This endpoint requires the `MANAGE_MESSAGES` permission to be present on the current user.
        /// Fires a Message Reaction Remove All Gateway event.
        pub fn nukeReactions(
            self: *Self,
            channel_id: Snowflake,
            message_id: Snowflake,
        ) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}/reactions", .{ channel_id.into(), message_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        /// Deletes all the reactions for a given emoji on a message.
        /// This endpoint requires the `MANAGE_MESSAGES` permission to be present on the current user.
        /// Fires a Message Reaction Remove Emoji Gateway event.
        pub fn nukeReactionsFor(
            self: *Self,
            channel_id: Snowflake,
            message_id: Snowflake,
            emoji: Types.Emoji,
        ) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}/reactions/{s}:{d}", .{
                channel_id.into(),
                message_id.into(),
                emoji.name.?,
                emoji.id.?.into(),
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        /// Delete a message.
        /// If operating on a guild channel and trying to delete a message that was not sent by the current user, this endpoint requires the `MANAGE_MESSAGE` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Message Delete Gateway event.
        /// TODO: implement audit-log header?
        pub fn deleteMessage(self: *Self, channel_id: Snowflake, message_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}", .{ channel_id.into(), message_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(path);
        }

        /// Delete multiple messages in a single request.
        /// This endpoint can only be used on guild channels and requires the `MANAGE_MESSAGES` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Message Delete Bulk Gateway event.
        ///
        /// Any message IDs given that do not exist or are invalid will count towards the minimum and maximum message count (currently 2 and 100 respectively).
        pub fn bulkDeleteMessages(self: *Self, channel_id: Snowflake, messages: []Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/bulk-delete", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.post4(path, .{ .messages = messages });
        }

        /// Edit a previously sent message.
        /// The fields `content`, `embeds`, and `flags` can be edited by the original message author.
        /// Other users can only edit flags and only if they have the `MANAGE_MESSAGES` permission in the corresponding channel.
        /// When specifying flags, ensure to include all previously set flags/bits in addition to ones that you are modifying.
        /// Only `flags` documented in the table below may be modified by users (unsupported flag changes are currently ignored without error).
        ///
        /// When the `content` field is edited, the mentions array in the message object will be reconstructed from scratch based on the new content.
        /// The `allowed_mentions` field of the edit request controls how this happens.
        /// If there is no explicit `allowed_mentions` in the edit request, the content will be parsed with default allowances, that is, without regard to whether or not an `allowed_mentions` was present in the request that originally created the message.
        ///
        /// Returns a message object. Fires a Message Update Gateway event.
        /// @remarks Starting with API v10, the attachments array must contain all attachments that should be present after edit, including retained and new attachments provided in the request body.
        pub fn editMessage(self: *Self, channel_id: Snowflake, message_id: Snowflake, edit_message: Partial(Types.CreateMessage)) RequestFailedError!Result(Types.Message) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}", .{ channel_id.into(), message_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.patch(Types.Message, path, edit_message);
            return res;
        }

        // Methods for channel-related actions
        // not yet finished

        /// Get a channel by ID.
        /// Returns a channel object.
        /// If the channel is a thread, a thread member object is included in the returned result.
        pub fn fetchChannel(self: *Self, channel_id: Snowflake) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.get(Types.Channel, path);
            return res;
        }

        /// Update a channel's settings.
        /// Returns a channel on success, and a 400 BAD REQUEST on invalid parameters.
        /// All JSON parameters are optional.
        pub fn editChannel(self: *Self, channel_id: Snowflake, edit_channel: Types.ModifyChannel, reason: ?[]const u8) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const res = try req.patch(Types.Channel, path, edit_channel);
            return res;
        }

        /// Delete a channel, or close a private message.
        /// Requires the `MANAGE_CHANNELS` permission for the guild, or `MANAGE_THREADS` if the channel is a thread.
        /// Deleting a category does not delete its child channels; they will have their parent_id removed and a Channel Update Gateway event will fire for each of them.
        /// Returns a channel object on success.
        /// Fires a Channel Delete Gateway event (or Thread Delete if the channel was a thread).
        pub fn deleteChannel(self: *Self, channel_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(path);
        }

        pub const ModifyChannelPermissions = struct {
            /// the bitwise value of all allowed permissions (default "0")
            allow: ?Types.BitwisePermissionFlags,
            /// the bitwise value of all disallowed permissions (default "0")
            deny: ?Types.BitwisePermissionFlags,
            /// 0 for a role or 1 for a member
            type: u1,
        };

        /// Edit the channel permission overwrites for a user or role in a channel.
        /// Only usable for guild channels.
        /// Requires the `MANAGE_ROLES` permission.
        /// Only permissions your bot has in the guild or parent channel (if applicable) can be allowed/denied (unless your bot has a `MANAGE_ROLES` overwrite in the channel).
        /// Returns a 204 empty response on success.
        /// Fires a Channel Update Gateway event. For more information about permissions, see permissions.
        pub fn editChannelPermissions(
            self: *Self,
            channel_id: Snowflake,
            overwrite_id: Snowflake,
            params: ModifyChannelPermissions,
            reason: ?[]const u8,
        ) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/permissions/{d}", .{ channel_id.into(), overwrite_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.put5(path, params);
        }

        /// Returns a list of invite objects (with invite metadata) for the channel.
        /// Only usable for guild channels.
        /// Requires the `MANAGE_CHANNELS` permission.
        pub fn fetchChannelInvites(self: *Self, channel_id: Snowflake) RequestFailedError!Result([]Types.Invite) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/invites", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const invites = try req.get([]Types.Invite, path);
            return invites;
        }

        /// Create a new invite object for the channel.
        /// Only usable for guild channels.
        /// Requires the `CREATE_INSTANT_INVITE` permission.
        /// All JSON parameters for this route are optional, however the request body is not.
        /// If you are not sending any fields, you still have to send an empty JSON object ({}).
        /// Returns an invite object. Fires an Invite Create Gateway event.
        pub fn createChannelInvite(self: *Self, channel_id: Snowflake, params: Types.CreateChannelInvite, reason: ?[]const u8) RequestFailedError!Result(Types.Invite) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/invites", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const invite = try req.post(Types.Invite, path, params);
            return invite;
        }

        /// Delete a channel permission overwrite for a user or role in a channel.
        /// Only usable for guild channels.
        /// Requires the `MANAGE_ROLES` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Channel Update Gateway event.
        /// For more information about permissions, see permissions
        pub fn deleteChannelPermission(self: *Self, channel_id: Snowflake, overwrite_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/permissions/{d}", .{ channel_id.into(), overwrite_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(path);
        }

        /// Follow an Announcement Channel to send messages to a target channel.
        /// Requires the `MANAGE_WEBHOOKS` permission in the target channel.
        /// Returns a followed channel object.
        /// Fires a Webhooks Update Gateway event for the target channel.
        /// TODO: support reason header
        pub fn followAnnouncementChannel(
            self: *Self,
            channel_id: Snowflake,
            params: Types.FollowAnnouncementChannel,
            reason: ?[]const u8,
        ) RequestFailedError!Result(Types.FollowedChannel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/followers", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const fc = try req.post(Types.FollowedChannel, path, params);
            return fc;
        }

        /// Post a typing indicator for the specified channel, which expires after 10 seconds.
        /// Returns a 204 empty response on success.
        /// Fires a Typing Start Gateway event.
        ///
        /// Generally bots should not use this route. However, if a bot is responding to a command and expects the computation to take a few seconds, this endpoint may be called to let the user know that the bot is processing their message.
        pub fn triggerTypingIndicator(self: *Self, channel_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/typing", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.post4(path);
        }

        /// Returns all pinned messages in the channel as an array of message objects.
        pub fn fetchPins(self: *Self, channel_id: Snowflake) RequestFailedError!Result([]Types.Message) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/pins", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const messages = try req.get([]Types.Message, path);
            return messages;
        }

        /// Pin a message in a channel.
        /// Requires the `MANAGE_MESSAGES` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Channel Pins Update Gateway event.
        pub fn pinMessage(self: *Self, channel_id: Snowflake, message_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/pins/{d}", .{ channel_id.into(), message_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.post5(path);
        }

        /// Unpin a message in a channel.
        /// Requires the `MANAGE_MESSAGES` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Channel Pins Update Gateway event.
        pub fn unpinMessage(self: *Self, channel_id: Snowflake, message_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/pins/{d}", .{ channel_id.into(), message_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(path);
        }

        pub fn groupDmAddRecipient() !void {
            @panic("unimplemented\n");
        }

        pub fn groupDmRemoveRecipient() !void {
            @panic("unimplemented\n");
        }

        /// Creates a new thread from an existing message.
        /// Returns a channel on success, and a 400 BAD REQUEST on invalid parameters.
        /// Fires a Thread Create and a Message Update Gateway event.
        ///
        /// When called on a `GUILD_TEXT` channel, creates a `PUBLIC_THREAD`.
        /// When called on a `GUILD_ANNOUNCEMENT` channel, creates a `ANNOUNCEMENT_THREAD`.
        /// Does not work on a `GUILD_FORUM` or a `GUILD_MEDIA` channel.
        /// The id of the created thread will be the same as the id of the source message, and as such a message can only have a single thread created from it.
        pub fn startThreadFromMessage(
            self: *Self,
            channel_id: Snowflake,
            message_id: Snowflake,
            params: Types.StartThreadFromMessage,
            reason: ?[]const u8,
        ) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/messages/{d}/threads", .{ channel_id.into(), message_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const thread = try req.post(Types.Channel, path, params);
            return thread;
        }

        /// Creates a new thread that is not connected to an existing message.
        /// Returns a channel on success, and a 400 BAD REQUEST on invalid parameters.
        /// Fires a Thread Create Gateway event.
        pub fn startThread(self: *Self, channel_id: Snowflake, params: Types.StartThreadFromMessage, reason: ?[]const u8) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/threads", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const thread = try req.post(Types.Channel, path, params);
            return thread;
        }

        /// Creates a new thread in a forum or a media channel, and sends a message within the created thread.
        /// Returns a channel, with a nested message object, on success, and a 400 BAD REQUEST on invalid parameters.
        /// Fires a Thread Create and Message Create Gateway event.
        pub fn startThreadInForumOrMediaChannel(self: *Self, channel_id: Snowflake, params: Types.StartThreadFromMessage, reason: ?[]const u8) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/threads", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const thread = try req.post(Types.Channel, path, params);
            return thread;
        }

        pub const StartThreadInForumOrMediaChannelWithFiles = struct {
            start_thread: Types.StartThreadFromMessage,
            files: []FileData,
        };

        /// same as `startThreadInForumOrMediaChannel`
        /// maybe rename this shit?
        pub fn startThreadInForumOrMediaChannelWithFiles(
            self: *Self,
            channel_id: Snowflake,
            options: StartThreadInForumOrMediaChannelWithFiles,
            reason: ?[]const u8,
        ) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/threads", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);
            const thread = try req.post3(Types.Channel, path, options.start_thread, options.files);
            return thread;
        }

        /// Adds the current user to a thread. Also requires the thread is not archived.
        /// Returns a 204 empty response on success.
        /// Fires a Thread Members Update and a Thread Create Gateway event.
        pub fn joinThread(self: *Self, channel_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/thread-members/@me", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.put3(path);
        }

        /// Adds another member to a thread. Requires the ability to send messages in the thread. Also requires the thread is not archived.
        /// Returns a 204 empty response if the member is successfully added or was already a member of the thread.
        /// Fires a Thread Members Update Gateway event.
        pub fn addMemberToThread(self: *Self, channel_id: Snowflake, user_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/thread-members/{d}", .{ channel_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.put3(path);
        }

        /// Removes the current user from a thread. Also requires the thread is not archived.
        /// Returns a 204 empty response on success.
        /// Fires a Thread Members Update Gateway event.
        pub fn leaveThread(self: *Self, channel_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/thread-members/@me", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        /// Removes another member from a thread.
        /// Requires the `MANAGE_THREADS` permission, or the creator of the thread if it is a `PRIVATE_THREAD`.
        /// Also requires the thread is not archived.
        /// Returns a 204 empty response on success.
        /// Fires a Thread Members Update Gateway event.
        pub fn removeMemberFromThread(self: *Self, channel_id: Snowflake, user_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/thread-members/{d}", .{ channel_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        /// Returns a thread member object for the specified user if they are a member of the thread, returns a 404 response otherwise.
        ///
        /// When `with_member``is set to true, the thread member object will include a member field containing a guild member object.
        pub fn fetchThreadMember(
            self: *Self,
            channel_id: Snowflake,
            user_id: Snowflake,
            with_member: bool,
        ) RequestFailedError!Result(Types.ThreadMember) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/thread-members/{d}?with_member={s}", .{
                channel_id.into(),
                user_id.into(),
                with_member,
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const thread_member = try req.get(Types.ThreadMember, path);
            return thread_member;
        }

        /// Returns array of thread members objects that are members of the thread.
        ///
        /// When `with_member` is set to true, the results will be paginated and each thread member object will include a member field containing a guild member object.
        /// TODO: actually include query string
        pub fn fetchThreadMembers(
            self: *Self,
            channel_id: Snowflake,
        ) RequestFailedError!Result([]Types.ThreadMember) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/thread-members/", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const thread_members = try req.get([]Types.ThreadMember, path);
            return thread_members;
        }

        /// Returns archived threads in the channel that are public.
        /// When called on a `GUILD_TEXT` channel, returns threads of type `PUBLIC_THREAD`.
        /// When called on a `GUILD_ANNOUNCEMENT` channel returns threads of type `ANNOUNCEMENT_THREAD`.
        /// Threads are ordered by `archive_timestamp`, in descending order.
        /// Requires the `READ_MESSAGE_HISTORY` permission.
        /// TODO: implement query string params
        pub fn listPublicArchivedThreads(self: *Self, channel_id: Snowflake) RequestFailedError!Result(Types.ArchivedThreads) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/threads/archived/public", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const threads = try req.get(Types.ArchivedThreads, path);
            return threads;
        }

        /// Returns archived threads in the channel that are of type `PRIVATE_THREAD`.
        /// Threads are ordered by `archive_timestamp`, in descending order.
        /// Requires both the `READ_MESSAGE_HISTORY` and `MANAGE_THREADS` permissions.
        /// TODO: implement query string params
        pub fn listPrivateArchivedThreads(self: *Self, channel_id: Snowflake) RequestFailedError!Result(Types.ArchivedThreads) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/threads/archived/private", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const threads = try req.get(Types.ArchivedThreads, path);
            return threads;
        }

        /// Returns archived threads in the channel that are of type `PRIVATE_THREAD`, and the user has joined.
        /// Threads are ordered by their id, in descending order.
        /// Requires the `READ_MESSAGE_HISTORY` permission.
        /// TODO: implement query string params
        pub fn listMyPrivateArchivedThreads(self: *Self, channel_id: Snowflake) RequestFailedError!Result(Types.ArchivedThreads) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/users/@me/threads/archived/private", .{channel_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const threads = try req.get(Types.ArchivedThreads, path);
            return threads;
        }

        /// perhaps they abused this endpoint so it remains with no documentation - Yuzu
        pub fn createChannel(self: *Self, guild_id: Snowflake, create_channel: Types.CreateGuildChannel) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/channels", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.post(Types.Channel, path, create_channel);
            return res;
        }

        // Methods for guild-related actions

        /// Method to fetch a guild
        /// Returns the guild object for the given id.
        /// If `with_counts` is set to true, this endpoint will also return `approximate_member_count` and `approximate_presence_count` for the guild.
        pub fn fetchGuild(self: *Self, guild_id: Snowflake, with_counts: ?bool) RequestFailedError!Result(Types.Guild) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addQueryParam("with_counts", with_counts);

            const res = try req.get(Types.Guild, path);
            return res;
        }

        /// Method to fetch a guild preview
        /// Returns the guild preview object for the given id. If the user is not in the guild, then the guild must be discoverable.
        pub fn fetchGuildPreview(self: *Self, guild_id: Snowflake) RequestFailedError!Result(Types.GuildPreview) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/preview", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.get(Types.GuildPreview, path);
            return res;
        }

        /// Method to fetch a guild's channels
        /// Returns a list of guild channel objects. Does not include threads.
        /// TODO: implement query string parameters
        pub fn fetchGuildChannels(self: *Self, guild_id: Snowflake) RequestFailedError!Result([]Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/channels", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.get([]Types.Channel, path);
            return res;
        }

        /// Method to create a guild channel
        /// Create a new channel object for the guild.
        /// Requires the `MANAGE_CHANNELS` permission.
        /// If setting permission overwrites, only permissions your bot has in the guild can be allowed/denied.
        /// Setting `MANAGE_ROLES` permission in channels is only possible for guild administrators.
        /// Returns the new channel object on success.
        /// Fires a Channel Create Gateway event.
        pub fn createGuildChannel(self: *Self, guild_id: Snowflake, create_guild_channel: Types.CreateGuildChannel) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/channels", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.post(Types.Channel, path, create_guild_channel);
            return res;
        }

        /// Method to edit a guild channel's positions
        /// Create a new channel object for the guild.
        /// Requires the `MANAGE_CHANNELS` permission.
        /// If setting permission overwrites, only permissions your bot has in the guild can be allowed/denied.
        /// Setting `MANAGE_ROLES` permission in channels is only possible for guild administrators.
        /// Returns the new channel object on success. Fires a Channel Create Gateway event.
        pub fn editGuildChannelPositions(self: *Self, guild_id: Snowflake, edit_guild_channel: Types.ModifyGuildChannelPositions) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/channels", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.patch2(Types.Channel, path, edit_guild_channel);
        }

        /// Method to get a guild's active threads
        /// Returns all active threads in the guild, including public and private threads.
        /// Threads are ordered by their `id`, in descending order.
        pub fn fetchGuildActiveThreads(self: *Self, guild_id: Snowflake) RequestFailedError!Result(Types.Channel) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/threads/active", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.get([]Types.Channel, path);
            return res;
        }

        /// Method to get a member
        /// Returns a guild member object for the specified user.
        pub fn fetchMember(self: *Self, guild_id: Snowflake, user_id: Snowflake) RequestFailedError!Result(Types.Member) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/{d}", .{ guild_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.get(Types.Member, path);
            return res;
        }

        pub const ListGuildMembersQuery = struct {
            /// max number of members to return (1-1000)
            limit: u16 = 1,
            /// the highest user id in the previous page
            after: Snowflake = Snowflake.from(0),
        };

        /// Method to get the members of a guild
        /// Returns a list of guild member objects that are members of the guild.
        pub fn fetchMembers(self: *Self, guild_id: Snowflake, query: ListGuildMembersQuery) RequestFailedError!Result([]Types.Member) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addQueryParam("limit", query.limit);
            try req.addQueryParam("after", query.after);

            const res = try req.get([]Types.Member, path);
            return res;
        }

        pub const SearchGuildMembersQuery = struct {
            /// Query string to match username(s) and nickname(s) against
            query: []const u8,
            /// max number of members to return (1-1000)
            limit: u16,
        };

        /// Method to find members
        /// Returns a list of guild member objects whose username or nickname starts with a provided string.
        pub fn searchMembers(self: *Self, guild_id: Snowflake, query: SearchGuildMembersQuery) RequestFailedError!Result([]Types.Member) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/search", .{
                guild_id.into(),
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addQueryParam("query", query.query);
            try req.addQueryParam("limit", query.limit);

            const res = try req.get([]Types.Member, path);
            return res;
        }

        /// Adds a user to the guild, provided you have a valid oauth2 access token for the user with the guilds.join scope.
        /// Returns a 201 Created with the guild member as the body, or 204 No Content if the user is already a member of the guild.
        /// Fires a Guild Member Add Gateway event.
        ///
        /// For guilds with Membership Screening enabled, this endpoint will default to adding new members as pending in the guild member object.
        /// Members that are pending will have to complete membership screening before they become full members that can talk.
        pub fn addMember(self: *Self, guild_id: Snowflake, user_id: Snowflake, credentials: Types.AddGuildMember) RequestFailedError!?Result(Types.Member) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/{d}", .{ guild_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.put2(Types.Member, path, credentials);
            return res;
        }

        /// Method to edit a member's attributes
        /// Modify attributes of a guild member.
        /// Returns a 200 OK with the guild member as the body.
        /// Fires a Guild Member Update Gateway event. If the channel_id is set to null,
        /// this will force the target user to be disconnected from voice.
        pub fn editMember(
            self: *Self,
            guild_id: Snowflake,
            user_id: Snowflake,
            attributes: Types.ModifyGuildMember,
            reason: ?[]const u8,
        ) RequestFailedError!?Result(Types.Member) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/{d}", .{ guild_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const res = try req.patch(Types.Member, path, attributes);
            return res;
        }

        pub fn editCurrentMember(self: *Self, guild_id: Snowflake, attributes: Types.ModifyGuildMember, reason: ?[]const u8) RequestFailedError!?Result(Types.Member) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/@me", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const res = try req.patch(Types.Member, path, attributes);
            return res;
        }

        /// change's someones's nickname
        pub fn changeNickname(self: *Self, guild_id: Snowflake, user_id: Snowflake, nick: []const u8, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/{d}", .{ guild_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const res = try req.patch(Types.Member, path, .{ .nick = nick });
            return res;
        }

        /// change's someones's nickname
        pub fn changeMyNickname(self: *Self, guild_id: Snowflake, nick: []const u8, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/@me", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const res = try req.patch(Types.Member, path, .{ .nick = nick });
            return res;
        }

        /// Adds a role to a guild member. Requires the `MANAGE_ROLES` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Guild Member Update Gateway event.
        pub fn addRole(
            self: *Self,
            guild_id: Snowflake,
            user_id: Snowflake,
            role_id: Snowflake,
            reason: ?[]const u8,
        ) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/{d}/roles/{d}", .{
                guild_id.into(),
                user_id.into(),
                role_id.into(),
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.put3(path);
        }

        /// Removes a role from a guild member.
        /// Requires the `MANAGE_ROLES` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Guild Member Update Gateway event.
        pub fn removeRole(
            self: *Self,
            guild_id: Snowflake,
            user_id: Snowflake,
            role_id: Snowflake,
            reason: ?[]const u8,
        ) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/{d}/roles/{d}", .{
                guild_id.into(),
                user_id.into(),
                role_id.into(),
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(path);
        }

        /// Remove a member from a guild.
        /// Requires `KICK_MEMBERS` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Guild Member Remove Gateway event.
        pub fn kickMember(
            self: *Self,
            guild_id: Snowflake,
            user_id: Snowflake,
            reason: ?[]const u8,
        ) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/members/{d}", .{ guild_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(path);
        }

        /// Provide a user id to before and after for pagination.
        /// Users will always be returned in ascending order by user.id.
        /// If both before and after are provided, only before is respected.
        pub const GetGuildBansQuery = struct {
            limit: ?u16 = 1000,
            before: ?Snowflake,
            after: ?Snowflake,
        };

        /// Returns a list of ban objects for the users banned from this guild.
        /// Requires the `BAN_MEMBERS` permission.
        /// TODO: add query params
        pub fn fetchBans(
            self: *Self,
            guild_id: Snowflake,
        ) RequestFailedError!Result([]Types.Ban) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/bans", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.get([]Types.Ban, path);
            return res;
        }

        /// Returns a ban object for the given user or a 404 not found if the ban cannot be found.
        /// Requires the `BAN_MEMBERS` permission.
        pub fn fetchBan(self: *Self, guild_id: Snowflake, user_id: Snowflake) RequestFailedError!Result(Types.Ban) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/bans/{d}", .{ guild_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.get(Types.Ban, path);
            return res;
        }

        /// Create a guild ban, and optionally delete previous messages sent by the banned user.
        /// Requires the `BAN_MEMBERS` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Guild Ban Add Gateway event.
        pub fn ban(self: *Self, guild_id: Snowflake, user_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/bans/{d}", .{ guild_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.put3(path);
        }

        /// Remove the ban for a user. Requires the `BAN_MEMBERS` permissions.
        /// Returns a 204 empty response on success.
        /// Fires a Guild Ban Remove Gateway event.
        pub fn unban(self: *Self, guild_id: Snowflake, user_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/bans/{d}", .{ guild_id.into(), user_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(path);
        }

        /// Ban up to 200 users from a guild, and optionally delete previous messages sent by the banned users.
        /// Requires both the `BAN_MEMBERS` and `MANAGE_GUILD` permissions.
        /// Returns a 200 response on success, including the fields banned_users with the IDs of the banned users
        /// and failed_users with IDs that could not be banned or were already banned.
        pub fn bulkBan(self: *Self, guild_id: Snowflake, bulk_ban: Types.CreateGuildBan, reason: ?[]const u8) RequestFailedError!Result(Types.BulkBan) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/bulk-ban", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const res = try req.post(Types.BulkBan, path, bulk_ban);
            return res;
        }

        /// Method to delete a guild
        /// Delete a guild permanently. User must be owner.
        /// Returns 204 No Content on success.
        /// Fires a Guild Delete Gateway event.
        pub fn deleteGuild(self: *Self, guild_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        /// Method to edit a guild
        /// Modify a guild's settings. Requires the `MANAGE_GUILD` permission.
        /// Returns the updated guild object on success.
        /// Fires a Guild Update Gateway event.
        pub fn editGuild(self: *Self, guild_id: Snowflake, edit_guild: Types.ModifyGuild) RequestFailedError!Result(Types.Guild) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.patch(Types.Guild, path, edit_guild);
            return res;
        }

        pub fn createGuild(self: *Self, create_guild: Partial(Types.CreateGuild)) RequestFailedError!Result(Types.Guild) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds", .{});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const res = try req.post(Types.Guild, path, create_guild);
            return res;
        }

        /// Create a new role for the guild.
        /// Requires the `MANAGE_ROLES` permission.
        /// Returns the new role object on success.
        /// Fires a Guild Role Create Gateway event.
        /// All JSON params are optional.
        pub fn createRole(self: *Self, guild_id: Snowflake, create_role: Partial(Types.CreateGuildRole), reason: ?[]const u8) RequestFailedError!Result(Types.Role) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/roles", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const res = try req.post(Types.Role, path, create_role);
            return res;
        }

        /// Modify the positions of a set of role objects for the guild.
        /// Requires the `MANAGE_ROLES` permission.
        /// Returns a list of all of the guild's role objects on success.
        /// Fires multiple Guild Role Update Gateway events.
        pub fn editRole(
            self: *Self,
            guild_id: Snowflake,
            role_id: Snowflake,
            edit_role: Partial(Types.ModifyGuildRole),
            reason: ?[]const u8,
        ) RequestFailedError!Result(Types.Role) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/roles/{d}", .{ guild_id.into(), role_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const res = try req.patch(Types.Role, path, edit_role);
            return res;
        }

        /// Modify a guild's MFA level.
        /// Requires guild ownership.
        /// Returns the updated level on success.
        /// Fires a Guild Update Gateway event.
        pub fn modifyMFALevel(self: *Self, guild_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/mfa", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(Types.Role, path);
        }

        /// Delete a guild role.
        /// Requires the `MANAGE_ROLES` permission.
        /// Returns a 204 empty response on success.
        /// Fires a Guild Role Delete Gateway event.
        pub fn deleteRole(self: *Self, guild_id: Snowflake, role_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/roles/{d}", .{ guild_id.into(), role_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(Types.Role, path);
        }

        /// Returns an object with one pruned key indicating the number of members that would be removed in a prune operation.
        /// Requires the `MANAGE_GUILD` and `KICK_MEMBERS` permissions.
        /// By default, prune will not remove users with roles.
        /// You can optionally include specific roles in your prune by providing the include_roles parameter.
        /// Any inactive user that has a subset of the provided role(s) will be counted in the prune and users with additional roles will not.
        pub fn fetchPruneCount(self: *Self, guild_id: Snowflake, query: Types.GetGuildPruneCountQuery) RequestFailedError!Result(struct { pruned: isize }) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/prune", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addQueryParam("days", query.days);
            try req.addQueryParam("include_roles", query.include_roles); // needs fixing perhaps

            const pruned = try req.get(struct { pruned: isize }, path);
            return pruned;
        }

        /// Begin a prune operation.
        /// Requires the `MANAGE_GUILD` and `KICK_MEMBERS` permissions.
        /// Returns an object with one `pruned` key indicating the number of members that were removed in the prune operation.
        /// For large guilds it's recommended to set the `compute_prune_count` option to false, forcing `pruned` to `null`.
        /// Fires multiple Guild Member Remove Gateway events.
        ///
        /// By default, prune will not remove users with roles.
        /// You can optionally include specific roles in your prune by providing the `include_roles` parameter.
        /// Any inactive user that has a subset of the provided role(s) will be included in the prune and users with additional roles will not.
        pub fn beginGuildPrune(
            self: *Self,
            guild_id: Snowflake,
            params: Types.BeginGuildPrune,
            reason: ?[]const u8,
        ) RequestFailedError!Result(struct { pruned: isize }) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/prune", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const pruned = try req.post(struct { pruned: isize }, path, params);
            return pruned;
        }

        /// Returns a list of voice region objects for the guild.
        /// Unlike the similar /voice route, this returns VIP servers when the guild is VIP-enabled.
        pub fn fetchVoiceRegion(self: *Self, guild_id: Snowflake) RequestFailedError!Result([]Types.VoiceRegion) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/regions", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const regions = try req.get([]Types.VoiceRegion, path);
            return regions;
        }

        /// Returns a list of invite objects (with invite metadata) for the guild.
        /// Requires the `MANAGE_GUILD` permission.
        pub fn fetchInvites(self: *Self, guild_id: Snowflake) RequestFailedError!Result([]Types.Invite) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/invites", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const invites = try req.get([]Types.Invite, path);
            return invites;
        }

        /// Returns a list of integration objects for the guild.
        /// Requires the `MANAGE_GUILD` permission.
        pub fn fetchIntegrations(self: *Self, guild_id: Snowflake) RequestFailedError!Result([]Types.Integration) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/integrations", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const integrations = try req.get([]Types.integrations, path);
            return integrations;
        }

        /// Returns a list of integration objects for the guild.
        /// Requires the `MANAGE_GUILD` permission.
        pub fn deleteIntegration(self: *Self, guild_id: Snowflake, integration_id: Snowflake, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/integrations/{d}", .{
                guild_id.into(),
                integration_id.into(),
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(path);
        }

        /// Returns a guild widget settings object.
        /// Requires the `MANAGE_GUILD` permission.
        pub fn fetchWidgetSettings(self: *Self, guild_id: Snowflake) RequestFailedError!Result(Types.GuildWidgetSettings) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/widget", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const widget = try req.get(Types.GuildWidgetSettings, path);
            return widget;
        }

        /// Modify a guild widget settings object for the guild.
        /// All attributes may be passed in with JSON and modified.
        /// Requires the `MANAGE_GUILD` permission.
        /// Returns the updated guild widget settings object.
        /// Fires a Guild Update Gateway event.
        pub fn editWidget(self: *Self, guild_id: Snowflake, attributes: Partial(Types.GuildWidget), reason: ?[]const u8) RequestFailedError!Result(Types.GuildWidget) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/widget", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const widget = try req.patch(Types.GuildWidget, path, attributes);
            return widget;
        }

        /// Returns the widget for the guild.
        /// Fires an Invite Create Gateway event when an invite channel is defined and a new Invite is generated.
        pub fn fetchWidget(self: *Self, guild_id: Snowflake) RequestFailedError!Result(Types.GuildWidget) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/widget.json", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const widget = try req.get(Types.GuildWidget, path);
            return widget;
        }

        /// Returns a partial invite object for guilds with that feature enabled.
        /// Requires the `MANAGE_GUILD` permission. code will be null if a vanity url for the guild is not set.
        pub fn fetchVanityUrl(self: *Self, guild_id: Snowflake) RequestFailedError!Result(Partial(Types.Invite)) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/vanity-url", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const invite = try req.get(Partial(Types.Invite), path);
            return invite;
        }

        /// Returns a PNG image widget for the guild.
        /// Requires no permissions or authentication.
        pub fn fetchWidgetImage(self: *Self, guild_id: Snowflake) RequestFailedError![]const u8 {
            _ = self;
            _ = guild_id;
            @panic("unimplemented");
        }

        /// Modify the guild's Welcome Screen.
        /// Requires the `MANAGE_GUILD` permission.
        /// Returns the updated Welcome Screen object. May fire a Guild Update Gateway event.
        /// TODO: add query params
        pub fn fetchWelcomeScreen(self: *Self, guild_id: Snowflake) RequestFailedError!Result(Types.WelcomeScreen) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/welcome-screen", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const welcome_screen = try req.get(Types.WelcomeScreen, path);
            return welcome_screen;
        }

        /// Returns the Onboarding object for the guild.
        pub fn fetchOnboarding(self: *Self, guild_id: Snowflake) RequestFailedError!Result(Types.GuildOnboarding) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/onboarding", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const ob = try req.get(Types.GuildOnboarding, path);
            return ob;
        }

        /// Returns the Onboarding object for the guild.
        pub fn editOnboarding(
            self: *Self,
            guild_id: Snowflake,
            onboarding: Types.GuildOnboardingPromptOption,
            reason: ?[]const u8,
        ) RequestFailedError!Result(Types.GuildOnboarding) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/onboarding", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            const ob = try req.put(Types.GuildOnboarding, path, onboarding);
            return ob;
        }

        // start user related endpoints

        /// Returns the user object of the requester's account.
        /// For OAuth2, this requires the identify scope, which will return the object without an email, and optionally the email scope, which returns the object with an email if the user has one.
        pub fn fetchMyself(self: *Self) RequestFailedError!Result(Types.User) {
            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.get(Types.User, "/users/@me");
        }

        /// Returns a user object for a given user ID.
        pub fn fetchUser(self: *Self, user_id: Snowflake) RequestFailedError!Result(Types.User) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/users/{d}", .{user_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const user = try req.get(Types.User, path);
            return user;
        }

        /// Returns a user object for a given user ID.
        pub fn editMyself(self: *Self, params: Types.ModifyCurrentUser) RequestFailedError!Result(Types.User) {
            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const user = try req.patch(Types.User, "/users/@me", params);
            return user;
        }

        /// Returns a list of partial guild objects the current user is a member of.
        /// For OAuth2, requires the guilds scope.
        pub fn fetchMyGuilds(self: *Self, params: Types.ModifyCurrentUser) RequestFailedError!Result([]Partial(Types.Guild)) {
            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const guilds = try req.patch(Types.User, "/users/@me/guilds", params);
            return guilds;
        }

        /// Returns a guild member object for the current user.
        /// Requires the guilds.members.read OAuth2 scope.
        pub fn fetchMyMember(self: *Self, guild_id: Snowflake) RequestFailedError!Result(Types.Member) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/users/@me/guilds/{d}/member", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const member = try req.get(Types.Member, path);
            return member;
        }

        /// Leave a guild. Returns a 204 empty response on success. Fires a Guild Delete Gateway event and a Guild Member Remove Gateway event.
        pub fn leaveGuild(self: *Self, guild_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/users/@me/guilds/{d}", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        /// Create a new DM channel with a user.
        /// Returns a DM channel object (if one already exists, it will be returned instead).
        pub fn dm(self: *Self, whom: Snowflake) RequestFailedError!Result(Types.Channel) {
            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.post(Types.Channel, "/users/@me/channels", .{ .recipient_id = whom });
        }

        /// Create a new group DM channel with multiple users.
        /// Returns a DM channel object.
        /// This endpoint was intended to be used with the now-deprecated GameBridge SDK.
        /// Fires a Channel Create Gateway event.
        pub fn groupDm(self: *Self, access_tokens: [][]const u8, whose: []struct { Snowflake, []const u8 }) RequestFailedError!Result(Types.Channel) {
            _ = self;
            _ = access_tokens;
            _ = whose;
            @panic("unimplemented\n");
        }

        /// Returns a list of connection objects. Requires the connections OAuth2 scope.
        pub fn fetchMyConnections(self: *Self) RequestFailedError!Result([]Types.Connection) {
            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const connections = try req.get([]Types.Connection, "/users/@me/connections");
            return connections;
        }

        pub fn fetchMyApplicationConnection(self: *Self) RequestFailedError!void {
            _ = self;
            @panic("unimplemented\n");
        }

        pub fn updateMyApplicationConnection(self: *Self) RequestFailedError!void {
            _ = self;
            @panic("unimplemented\n");
        }

        // start methods for emojis

        /// Returns a list of emoji objects for the given guild.
        /// Includes `user` fields if the bot has the `CREATE_GUILD_EXPRESSIONS` or `MANAGE_GUILD_EXPRESSIONS` permission.
        pub fn fetchEmojis(self: *Self, guild_id: Snowflake) RequestFailedError!Result([]Types.Emoji) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/emojis", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const emojis = try req.get([]Types.Emoji, path);
            return emojis;
        }

        /// Returns an emoji object for the given guild and emoji IDs.
        /// Includes the `user` field if the bot has the `MANAGE_GUILD_EXPRESSIONS` permission, or if the bot created the emoji and has the the `CREATE_GUILD_EXPRESSIONS` permission.
        pub fn fetchEmoji(self: *Self, guild_id: Snowflake, emoji_id: Snowflake) RequestFailedError!Result(Types.Emoji) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/emojis/{d}", .{ guild_id.into(), emoji_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const emoji = try req.get(Types.Emoji, path);
            return emoji;
        }

        /// Create a new emoji for the guild.
        /// Requires the `CREATE_GUILD_EXPRESSIONS` permission.
        /// Returns the new emoji object on success.
        /// Fires a Guild Emojis Update Gateway event.
        pub fn createEmoji(self: *Self, guild_id: Snowflake, emoji: Types.CreateGuildEmoji) RequestFailedError!Result(Types.Emoji) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/emojis", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.post(Types.Emoji, path, emoji);
        }

        /// Modify the given emoji.
        /// For emojis created by the current user, requires either the `CREATE_GUILD_EXPRESSIONS` or `MANAGE_GUILD_EXPRESSIONS` permission.
        /// For other emojis, requires the `MANAGE_GUILD_EXPRESSIONS` permission.
        /// Returns the updated emoji object on success.
        /// Fires a Guild Emojis Update Gateway event.
        pub fn editEmoji(self: *Self, guild_id: Snowflake, emoji: Types.ModifyGuildEmoji) RequestFailedError!Result(Types.Emoji) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/emojis", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.patch(Types.Emoji, path, emoji);
        }

        /// Delete the given emoji.
        /// For emojis created by the current user, requires either the `CREATE_GUILD_EXPRESSIONS` or `MANAGE_GUILD_EXPRESSIONS` permission.
        /// For other emojis, requires the `MANAGE_GUILD_EXPRESSIONS` permission.
        /// Returns 204 No Content on success.
        /// Fires a Guild Emojis Update Gateway event.
        pub fn deleteEmoji(self: *Self, guild_id: Snowflake, emoji_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/emojis/{d}", .{ guild_id.into(), emoji_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        /// Returns an object containing a list of emoji objects for the given application under the `items` key.
        /// Includes a `user` object for the team member that uploaded the emoji from the app's settings, or for the bot user if uploaded using the API.
        pub fn fetchApplicationEmojis(self: *Self, application_id: Snowflake) RequestFailedError!Result([]Types.Emoji) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/emojis", .{application_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const emojis = try req.get([]Types.Emoji, path);
            return emojis;
        }

        /// Returns an emoji object for the given application and emoji IDs. Includes the user field.
        pub fn fetchApplicationEmoji(self: *Self, application_id: Snowflake, emoji_id: Snowflake) RequestFailedError!Result(Types.Emoji) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/emojis/{d}", .{ application_id.into(), emoji_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const emoji = try req.get(Types.Emoji, path);
            return emoji;
        }

        /// Create a new emoji for the application. Returns the new emoji object on success.
        pub fn createApplicationEmoji(self: *Self, application_id: Snowflake, emoji: Types.CreateGuildEmoji) RequestFailedError!Result(Types.Emoji) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/emojis", .{application_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.post(Types.Emoji, path, emoji);
        }

        /// Modify the given emoji. Returns the updated emoji object on success.
        pub fn editApplicationEmoji(self: *Self, application_id: Snowflake, emoji: Types.ModifyGuildEmoji) RequestFailedError!Result(Types.Emoji) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/emojis", .{application_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.patch(Types.Emoji, path, emoji);
        }

        /// Delete the given emoji. Returns 204 No Content on success.
        pub fn deleteApplicationEmoji(self: *Self, application_id: Snowflake, emoji_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/emojis/{d}", .{ application_id.into(), emoji_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        // start invites

        /// Returns an invite object for the given code.
        pub fn fetchInvite(self: *Self, code: []const u8) RequestFailedError!Result(Types.Invite) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/invites/{s}", .{code});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.get(Types.Invite, path);
        }

        /// Delete an invite.
        /// Requires the `MANAGE_CHANNELS` permission on the channel this invite belongs to, or `MANAGE_GUILD` to remove any invite across the guild.
        /// Returns an invite object on success.
        /// Fires an Invite Delete Gateway event.
        pub fn deleteInvite(self: *Self, code: []const u8, reason: ?[]const u8) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/invites/{s}", .{code});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            try req.addHeader("X-Audit-Log-Reason", reason);

            return req.delete(path);
        }

        // poll stuff

        /// Get a list of users that voted for this specific answer.
        pub fn fetchAnswerVoters(
            self: *Self,
            channel_id: Snowflake,
            poll_id: Snowflake,
            answer_id: Snowflake,
        ) RequestFailedError!Result([]Types.User) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/polls/{d}/answers/{d}", .{
                channel_id.into(),
                poll_id.into(),
                answer_id.into(),
            });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const voters = try req.get([]Types.User, path);
            return voters;
        }

        /// Immediately ends the poll.
        /// You cannot end polls from other users.
        ///
        /// Returns a message object.
        /// Fires a Message Update Gateway event.
        pub fn endPoll(
            self: *Self,
            channel_id: Snowflake,
            poll_id: Snowflake,
        ) RequestFailedError!Result(Types.Message) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/channels/{d}/polls/{d}/expire", .{ channel_id.into(), poll_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const msg = try req.post(Types.Message, path);
            return msg;
        }

        /// Returns the application object associated with the requesting bot user.
        pub fn fetchMyApplication(self: *Self) RequestFailedError!Result(Types.Application) {
            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const app = try req.get(Types.Application, "/applications/@me");
            return app;
        }

        /// Edit properties of the app associated with the requesting bot user.
        /// Only properties that are passed will be updated.
        /// Returns the updated application object on success.
        pub fn editMyApplication(self: *Self, params: Types.ModifyApplication) RequestFailedError!Result(Types.Application) {
            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const app = try req.patch(Types.Application, "/applications/@me", params);
            return app;
        }

        /// Returns a serialized activity instance, if it exists.
        /// Useful for preventing unwanted activity sessions.
        pub fn fetchActivityInstance(self: *Self, application_id: Snowflake, insance: []const u8) RequestFailedError!Result(Types.ActivityInstance) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/activity-instances/{s}", .{ application_id.into(), insance });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const activity_instance = try req.get(Types.ActivityInstance, path);
            return activity_instance;
        }

        /// Returns a list of application role connection metadata objects for the given application.
        pub fn fetchApplicationRoleConnectionMetadataRecords(self: *Self, application_id: Snowflake) RequestFailedError!Result([]Types.ApplicationRoleConnection) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/role-connection/metadata", .{application_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.get([]Types.ApplicationRoleConnection, path);
        }

        /// Updates and returns a list of application role connection metadata objects for the given application.
        pub fn updateApplicationRoleConnectionMetadataRecords(self: *Self, application_id: Snowflake) RequestFailedError!Result([]Types.ApplicationRoleConnection) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/role-connection/metadata", .{application_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.put4([]Types.ApplicationRoleConnection, path);
        }

        /// Returns all entitlements for a given app, active and expired.
        pub fn fetchEntitlements(self: *Self, application_id: Snowflake) RequestFailedError!Result([]Types.Entitlement) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/entitlements", .{application_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const entitlements = try req.get([]Types.Entitlement, path);
            return entitlements;
        }

        /// Returns an entitlement.
        pub fn fetchEntitlement(self: *Self, application_id: Snowflake, entitlement_id: Snowflake) RequestFailedError!Result(Types.Entitlement) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/entitlements/{d}", .{ application_id.into(), entitlement_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const entitlement = try req.get(Types.Entitlement, path);
            return entitlement;
        }

        /// For One-Time Purchase consumable SKUs, marks a given entitlement for the user as consumed.
        /// The entitlement will have consumed: true when using List Entitlements.
        ///
        /// Returns a 204 No Content on success.
        pub fn consumeEntitlement(self: *Self, application_id: Snowflake, entitlement_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/entitlements/{d}/consume", .{ application_id.into(), entitlement_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.post5(path);
        }

        /// Creates a test entitlement to a given SKU for a given guild or user.
        /// Discord will act as though that user or guild has entitlement to your premium offering.
        ///
        /// This endpoint returns a partial entitlement object. It will not contain `subscription_id`, `starts_at`, or `ends_at`, as it's valid in perpetuity.
        ///
        /// After creating a test entitlement, you'll need to reload your Discord client. After doing so, you'll see that your server or user now has premium access.
        pub fn createTestEntitlement(
            self: *Self,
            application_id: Snowflake,
            params: Types.CreateTestEntitlement,
        ) RequestFailedError!Result(Partial(Types.Entitlement)) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/entitlements", .{application_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.post(Partial(Types.Entitlement), path, params);
        }

        /// Deletes a currently-active test entitlement. Discord will act as though that user or guild no longer has entitlement to your premium offering.
        ///
        /// Returns 204 No Content on success.
        pub fn deleteTestEntitlement(self: *Self, application_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/entitlements", .{application_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }

        /// Returns all SKUs for a given application.
        pub fn fetchSkus(self: *Self, application_id: Snowflake) RequestFailedError!Result([]Types.Sku) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/applications/{d}/skus", .{application_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const skus = try req.get([]Types.Sku, path);
            return skus;
        }

        // start sticker methods

        /// Returns a list of available sticker packs.
        pub fn fetchStickerPacks(self: *Self, guild_id: Snowflake) RequestFailedError!Result([]Types.StickerPack) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/sticker-packs", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const packs = try req.get([]Types.StickerPack, path);
            return packs;
        }

        /// Returns a sticker object for the given sticker ID.
        pub fn fetchSticker(self: *Self, sticker_id: Snowflake) RequestFailedError!Result(Types.Sticker) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/stickers/{d}", .{sticker_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const sticker = try req.get(Types.Sticker, path);
            return sticker;
        }

        /// Returns a sticker object for the given sticker ID.
        pub fn fetchStickerPack(self: *Self, pack_id: Snowflake) RequestFailedError!Result(Types.StickerPack) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/sticker-packs/{d}", .{pack_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const pack = try req.get(Types.StickerPack, path);
            return pack;
        }

        /// Returns an array of sticker objects for the given guild.
        /// Includes `user` fields if the bot has the `CREATE_GUILD_EXPRESSIONS` or `MANAGE_GUILD_EXPRESSIONS` permission.
        pub fn fetchGuildStickers(self: *Self, guild_id: Snowflake) RequestFailedError!Result([]Types.Sticker) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/stickers", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const stickers = try req.get([]Types.Sticker, path);
            return stickers;
        }

        /// Returns an array of sticker objects for the given guild.
        /// Includes `user` fields if the bot has the `CREATE_GUILD_EXPRESSIONS` or `MANAGE_GUILD_EXPRESSIONS` permission.
        pub fn fetchGuildSticker(self: *Self, guild_id: Snowflake, sticker_id: Snowflake) RequestFailedError!Result(Types.Sticker) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/stickers/{d}", .{ guild_id.into(), sticker_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            const sticker = try req.get(Types.Sticker, path);
            return sticker;
        }

        /// Create a new sticker for the guild.
        /// Requires the `CREATE_GUILD_EXPRESSIONS` permission.
        /// Returns the new sticker object on success.
        /// Fires a Guild Stickers Update Gateway event.
        pub fn createSticker(
            self: *Self,
            guild_id: Snowflake,
            sticker: Types.CreateModifyGuildSticker,
            file: FileData,
        ) RequestFailedError!Result(Types.Sticker) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/stickers", .{guild_id.into()});

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            var files = .{file};
            return req.post2(Types.Sticker, path, sticker, &files);
        }

        /// Modify the given sticker.
        /// For stickers created by the current user, requires either the `CREATE_GUILD_EXPRESSIONS` or `MANAGE_GUILD_EXPRESSIONS` permission.
        /// For other stickers, requires the `MANAGE_GUILD_EXPRESSIONS` permission.
        /// Returns the updated sticker object on success.
        /// Fires a Guild Stickers Update Gateway event.
        pub fn editSticker(self: *Self, guild_id: Snowflake, sticker_id: Snowflake, sticker: Types.CreateModifyGuildSticker) RequestFailedError!Result(Types.Sticker) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/stickers/{d}", .{ guild_id.into(), sticker_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.patch(Types.Sticker, path, sticker);
        }

        /// Delete the given sticker.
        /// For stickers created by the current user, requires either the `CREATE_GUILD_EXPRESSIONS` or `MANAGE_GUILD_EXPRESSIONS` permission.
        /// For other stickers, requires the `MANAGE_GUILD_EXPRESSIONS` permission.
        /// Returns 204 No Content on success.
        /// Fires a Guild Stickers Update Gateway event.
        pub fn deleteSticker(self: *Self, guild_id: Snowflake, sticker_id: Snowflake) RequestFailedError!Result(void) {
            var buf: [256]u8 = undefined;
            const path = try std.fmt.bufPrint(&buf, "/guilds/{d}/stickers/{d}", .{ guild_id.into(), sticker_id.into() });

            var req = FetchReq.init(self.allocator, self.details.token);
            defer req.deinit();

            return req.delete(path);
        }
        inline fn logif(self: *Self, comptime format: []const u8, args: anytype) void {
            internalLogif(self.log, format, args);
        }


    };
}
