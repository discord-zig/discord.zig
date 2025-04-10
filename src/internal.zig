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
const mem = std.mem;
const builtin = @import("builtin");
const Types = @import("./structures/types.zig");

pub const IdentifyProperties = struct {
    /// Operating system the shard runs on.
    os: []const u8,
    /// The "browser" where this shard is running on.
    browser: []const u8,
    /// The device on which the shard is running.
    device: []const u8,

    system_locale: ?[]const u8 = null, // TODO parse this
    browser_user_agent: ?[]const u8 = null,
    browser_version: ?[]const u8 = null,
    os_version: ?[]const u8 = null,
    referrer: ?[]const u8 = null,
    referring_domain: ?[]const u8 = null,
    referrer_current: ?[]const u8 = null,
    referring_domain_current: ?[]const u8 = null,
    release_channel: ?[]const u8 = null,
    client_build_number: ?u64 = null,
    client_event_source: ?[]const u8 = null,
};

/// https://discord.com/developers/docs/topics/gateway#get-gateway
pub const GatewayInfo = struct {
    /// The WSS URL that can be used for connecting to the gateway
    url: []const u8,
};

/// https://discord.com/developers/docs/events/gateway#session-start-limit-object
pub const GatewaySessionStartLimit = struct {
    /// Total number of session starts the current user is allowed
    total: u32,
    /// Remaining number of session starts the current user is allowed
    remaining: u32,
    /// Number of milliseconds after which the limit resets
    reset_after: u32,
    /// Number of identify requests allowed per 5 seconds
    max_concurrency: u32,
};

/// https://discord.com/developers/docs/topics/gateway#get-gateway-bot
pub const GatewayBotInfo = struct {
    url: []const u8,
    /// The recommended number of shards to use when connecting
    ///
    /// See https://discord.com/developers/docs/topics/gateway#sharding
    shards: u32,
    /// Information on the current session start limit
    ///
    /// See https://discord.com/developers/docs/topics/gateway#session-start-limit-object
    session_start_limit: ?GatewaySessionStartLimit,
};

pub const ShardDetails = struct {
    /// Bot token which is used to connect to Discord */
    token: []const u8,
    /// The URL of the gateway which should be connected to.
    url: []const u8 = "wss://gateway.discord.gg",
    /// The gateway version which should be used.
    version: ?usize = 10,
    /// The calculated intent value of the events which the shard should receive.
    intents: Types.Intents,
    /// Identify properties to use
    properties: IdentifyProperties = default_identify_properties,
};

pub const debug = std.log.scoped(.@"discord.zig");

pub const Log = union(enum) { yes, no };

pub const default_identify_properties = IdentifyProperties{
    .os = @tagName(builtin.os.tag),
    .browser = "discord.zig",
    .device = "discord.zig",
};

/// inspired from:
/// https://github.com/tiramisulabs/seyfert/blob/main/src/websocket/structures/timeout.ts
pub fn ConnectQueue(comptime T: type) type {
    return struct {
        pub const RequestWithShard = struct {
            callback: *const fn (self: *RequestWithShard) anyerror!void,
            shard: T,
        };

        // ignore this function
        // so it becomes a regular dequeue
        fn eq(_: void, _: RequestWithShard, _: RequestWithShard) std.math.Order {
            return std.math.Order.eq;
        }

        dequeue: std.PriorityDequeue(RequestWithShard, void, eq),
        allocator: mem.Allocator,
        remaining: usize,
        interval_time: u64 = 5000,
        running: bool = false,
        concurrency: usize = 1,

        pub fn init(allocator: mem.Allocator, concurrency: usize, interval_time: u64) !ConnectQueue(T) {
            return .{
                .allocator = allocator,
                .dequeue = std.PriorityDequeue(RequestWithShard, void, eq).init(allocator, {}),
                .remaining = concurrency,
                .interval_time = interval_time,
                .concurrency = concurrency,
            };
        }

        pub fn deinit(self: *ConnectQueue(T)) void {
            self.dequeue.deinit();
        }

        pub fn push(self: *ConnectQueue(T), req: RequestWithShard) !void {
            if (self.remaining == 0) {
                return self.dequeue.add(req);
            }
            self.remaining -= 1;

            if (!self.running) {
                try self.startInterval();
                self.running = true;
            }

            if (self.dequeue.count() < self.concurrency) {
                // perhaps store this?
                const ptr = try self.allocator.create(RequestWithShard);
                ptr.* = req;
                try req.callback(ptr);
                return;
            }

            return self.dequeue.add(req);
        }

        fn startInterval(self: *ConnectQueue(T)) !void {
            while (self.running) {
                std.Thread.sleep(std.time.ns_per_ms * (self.interval_time / self.concurrency));
                const req: ?RequestWithShard = self.dequeue.removeMin(); // pop front

                while (self.dequeue.count() == 0 and req == null) {}

                if (req) |r| {
                    const ptr = try self.allocator.create(RequestWithShard);
                    ptr.* = r;
                    try @call(.auto, r.callback, .{ptr});
                    return;
                }

                if (self.remaining < self.concurrency) {
                    self.remaining += 1;
                }

                if (self.dequeue.count() == 0) {
                    self.running = false;
                }
            }
        }
    };
}

pub const Bucket = struct {
    /// The queue of requests to acquire an available request. Mapped by (shardId, RequestWithPrio)
    queue: std.PriorityQueue(RequestWithPrio, void, Bucket.lessthan),

    limit: usize,
    refill_interval: u64,
    refill_amount: usize,

    /// The amount of requests that have been used up already.
    used: usize = 0,

    /// Whether or not the queue is already processing.
    processing: bool = false,

    /// Whether the timeout should be killed because there is already one running
    should_stop: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),

    /// The timestamp in milliseconds when the next refill is scheduled.
    refills_at: ?u64 = null,

    pub const RequestWithPrio = struct {
        callback: *const fn () void,
        priority: u32 = 1,
    };

    fn lessthan(_: void, a: RequestWithPrio, b: RequestWithPrio) std.math.Order {
        return std.math.order(a.priority, b.priority);
    }

    pub fn init(allocator: mem.Allocator, limit: usize, refill_interval: u64, refill_amount: usize) Bucket {
        return .{
            .queue = std.PriorityQueue(RequestWithPrio, void, lessthan).init(allocator, {}),
            .limit = limit,
            .refill_interval = refill_interval,
            .refill_amount = refill_amount,
        };
    }

    fn remaining(self: *Bucket) usize {
        if (self.limit < self.used) {
            return 0;
        } else {
            return self.limit - self.used;
        }
    }

    pub fn refill(self: *Bucket) std.Thread.SpawnError!void {
        // Lower the used amount by the refill amount
        self.used = if (self.refill_amount > self.used) 0 else self.used - self.refill_amount;

        // Reset the refills_at timestamp since it just got refilled
        self.refills_at = null;

        if (self.used > 0) {
            if (self.should_stop.load(.monotonic) == true) {
                self.should_stop.store(false, .monotonic);
            }
            const thread = try std.Thread.spawn(.{}, Bucket.timeout, .{self});
            thread.detach;
            self.refills_at = std.time.milliTimestamp() + self.refill_interval;
        }
    }

    fn timeout(self: *Bucket) void {
        while (!self.should_stop.load(.monotonic)) {
            self.refill();
            std.time.sleep(std.time.ns_per_ms * self.refill_interval);
        }
    }

    pub fn processQueue(self: *Bucket) std.Thread.SpawnError!void {
        if (self.processing) return;

        while (self.queue.remove()) |first_element| {
            if (self.remaining() != 0) {
                first_element.callback();
                self.used += 1;

                if (!self.should_stop.load(.monotonic)) {
                    const thread = try std.Thread.spawn(.{}, Bucket.timeout, .{self});
                    thread.detach;
                    self.refills_at = std.time.milliTimestamp() + self.refill_interval;
                }
            } else if (self.refills_at) |ra| {
                const now = std.time.milliTimestamp();
                if (ra > now) std.time.sleep(std.time.ns_per_ms * (ra - now));
            }
        }

        self.processing = false;
    }

    pub fn acquire(self: *Bucket, rq: RequestWithPrio) !void {
        try self.queue.add(rq);
        try self.processQueue();
    }
};

pub fn GatewayDispatchEvent(comptime T: type) type {
    return struct {
        application_command_permissions_update: ?*const fn (save: T, application_command_permissions: Types.ApplicationCommandPermissions) anyerror!void = undefined,
        auto_moderation_rule_create: ?*const fn (save: T, rule: Types.AutoModerationRule) anyerror!void = undefined,
        auto_moderation_rule_update: ?*const fn (save: T, rule: Types.AutoModerationRule) anyerror!void = undefined,
        auto_moderation_rule_delete: ?*const fn (save: T, rule: Types.AutoModerationRule) anyerror!void = undefined,
        auto_moderation_action_execution: ?*const fn (save: T, action_execution: Types.AutoModerationActionExecution) anyerror!void = undefined,

        channel_create: ?*const fn (save: T, chan: Types.Channel) anyerror!void = undefined,
        channel_update: ?*const fn (save: T, chan: Types.Channel) anyerror!void = undefined,
        /// this isn't send when the channel is not relevant to you
        channel_delete: ?*const fn (save: T, chan: Types.Channel) anyerror!void = undefined,
        channel_pins_update: ?*const fn (save: T, chan_pins_update: Types.ChannelPinsUpdate) anyerror!void = undefined,
        thread_create: ?*const fn (save: T, thread: Types.Channel) anyerror!void = undefined,
        thread_update: ?*const fn (save: T, thread: Types.Channel) anyerror!void = undefined,
        /// has `id`, `guild_id`, `parent_id`, and `type` fields.
        thread_delete: ?*const fn (save: T, thread: Types.Partial(Types.Channel)) anyerror!void = undefined,
        thread_list_sync: ?*const fn (save: T, data: Types.ThreadListSync) anyerror!void = undefined,
        thread_member_update: ?*const fn (save: T, guild_id: Types.ThreadMemberUpdate) anyerror!void = undefined,
        thread_members_update: ?*const fn (save: T, thread_data: Types.ThreadMembersUpdate) anyerror!void = undefined,
        // TODO: implement // guild_audit_log_entry_create: null = null,
        guild_create: ?*const fn (save: T, guild: Types.Guild) anyerror!void = undefined,
        guild_create_unavailable: ?*const fn (save: T, guild: Types.UnavailableGuild) anyerror!void = undefined,
        guild_update: ?*const fn (save: T, guild: Types.Guild) anyerror!void = undefined,
        /// this is not necessarily sent upon deletion of a guild
        /// but from when a user is *removed* therefrom
        guild_delete: ?*const fn (save: T, guild: Types.UnavailableGuild) anyerror!void = undefined,
        guild_ban_add: ?*const fn (save: T, gba: Types.GuildBanAddRemove) anyerror!void = undefined,
        guild_ban_remove: ?*const fn (save: T, gbr: Types.GuildBanAddRemove) anyerror!void = undefined,
        guild_emojis_update: ?*const fn (save: T, fields: Types.GuildEmojisUpdate) anyerror!void = undefined,
        guild_stickers_update: ?*const fn (save: T, fields: Types.GuildStickersUpdate) anyerror!void = undefined,
        guild_integrations_update: ?*const fn (save: T, fields: Types.GuildIntegrationsUpdate) anyerror!void = undefined,
        guild_member_add: ?*const fn (save: T, guild_id: Types.GuildMemberAdd) anyerror!void = undefined,
        guild_member_update: ?*const fn (save: T, fields: Types.GuildMemberUpdate) anyerror!void = undefined,
        guild_member_remove: ?*const fn (save: T, user: Types.GuildMemberRemove) anyerror!void = undefined,
        guild_members_chunk: ?*const fn (save: T, data: Types.GuildMembersChunk) anyerror!void = undefined,
        guild_role_create: ?*const fn (save: T, role: Types.GuildRoleCreate) anyerror!void = undefined,
        guild_role_delete: ?*const fn (save: T, role: Types.GuildRoleDelete) anyerror!void = undefined,
        guild_role_update: ?*const fn (save: T, role: Types.GuildRoleUpdate) anyerror!void = undefined,
        guild_scheduled_event_create: ?*const fn (save: T, s_event: Types.ScheduledEvent) anyerror!void = undefined,
        guild_scheduled_event_update: ?*const fn (save: T, s_event: Types.ScheduledEvent) anyerror!void = undefined,
        guild_scheduled_event_delete: ?*const fn (save: T, s_event: Types.ScheduledEvent) anyerror!void = undefined,
        guild_scheduled_event_user_add: ?*const fn (save: T, data: Types.ScheduledEventUserAdd) anyerror!void = undefined,
        guild_scheduled_event_user_remove: ?*const fn (save: T, data: Types.ScheduledEventUserRemove) anyerror!void = undefined,
        integration_create: ?*const fn (save: T, guild_id: Types.IntegrationCreateUpdate) anyerror!void = undefined,
        integration_update: ?*const fn (save: T, guild_id: Types.IntegrationCreateUpdate) anyerror!void = undefined,
        integration_delete: ?*const fn (save: T, guild_id: Types.IntegrationDelete) anyerror!void = undefined,
        interaction_create: ?*const fn (save: T, interaction: Types.MessageInteraction) anyerror!void = undefined,
        invite_create: ?*const fn (save: T, data: Types.InviteCreate) anyerror!void = undefined,
        invite_delete: ?*const fn (save: T, data: Types.InviteDelete) anyerror!void = undefined,
        message_create: ?*const fn (save: T, message: Types.Message) anyerror!void = undefined,
        message_update: ?*const fn (save: T, message: Types.Message) anyerror!void = undefined,
        message_delete: ?*const fn (save: T, log: Types.MessageDelete) anyerror!void = undefined,
        message_delete_bulk: ?*const fn (save: T, log: Types.MessageDeleteBulk) anyerror!void = undefined,
        message_reaction_add: ?*const fn (save: T, log: Types.MessageReactionAdd) anyerror!void = undefined,
        message_reaction_remove_all: ?*const fn (save: T, data: Types.MessageReactionRemoveAll) anyerror!void = undefined,
        message_reaction_remove: ?*const fn (save: T, data: Types.MessageReactionRemove) anyerror!void = undefined,
        message_reaction_remove_emoji: ?*const fn (save: T, data: Types.MessageReactionRemoveEmoji) anyerror!void = undefined,
        presence_update: ?*const fn (save: T, presence: Types.PresenceUpdate) anyerror!void = undefined,
        stage_instance_create: ?*const fn (save: T, stage_instance: Types.StageInstance) anyerror!void = undefined,
        stage_instance_update: ?*const fn (save: T, stage_instance: Types.StageInstance) anyerror!void = undefined,
        stage_instance_delete: ?*const fn (save: T, stage_instance: Types.StageInstance) anyerror!void = undefined,
        typing_start: ?*const fn (save: T, data: Types.TypingStart) anyerror!void = undefined,
        /// remember this is only sent when you change your profile yourself/your bot does
        user_update: ?*const fn (save: T, user: Types.User) anyerror!void = undefined,
        // will do these someday, music is rather pointless at this point in time
        // TODO: implement // voice_channel_effect_send: null = null,
        // TODO: implement // voice_state_update: null = null,
        // TODO: implement // voice_server_update: null = null,
        webhooks_update: ?*const fn (save: T, fields: Types.WebhookUpdate) anyerror!void = undefined,
        entitlement_create: ?*const fn (save: T, entitlement: Types.Entitlement) anyerror!void = undefined,
        entitlement_update: ?*const fn (save: T, entitlement: Types.Entitlement) anyerror!void = undefined,
        /// discord claims this is infrequent, therefore not throughoutly tested - Yuzu
        entitlement_delete: ?*const fn (save: T, entitlement: Types.Entitlement) anyerror!void = undefined,
        message_poll_vote_add: ?*const fn (save: T, poll: Types.PollVoteAdd) anyerror!void = undefined,
        message_poll_vote_remove: ?*const fn (save: T, poll: Types.PollVoteRemove) anyerror!void = undefined,

        ready: ?*const fn (save: T, data: Types.Ready) anyerror!void = undefined,
        // TODO: implement // resumed: null = null,
        any: ?*const fn (save: T, data: []const u8) anyerror!void = undefined,
    };
}
