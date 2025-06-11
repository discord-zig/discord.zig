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
const Types = @import("../structures/types.zig");

pub const debug = std.log.scoped(.@"discord.zig");

const Shard = @import("../shard/shard.zig");
pub const Log = union(enum) { yes, no };

pub inline fn logif(log: Log, comptime format: []const u8, args: anytype) void {
    switch (log) {
        .yes => debug.info(format, args),
        .no => {},
    }
}

pub const GatewayDispatchEvent = struct {
    application_command_permissions_update: ?*const fn (shard: *Shard, application_command_permissions: Types.ApplicationCommandPermissions) anyerror!void = null,
    auto_moderation_rule_create: ?*const fn (shard: *Shard, rule: Types.AutoModerationRule) anyerror!void = null,
    auto_moderation_rule_update: ?*const fn (shard: *Shard, rule: Types.AutoModerationRule) anyerror!void = null,
    auto_moderation_rule_delete: ?*const fn (shard: *Shard, rule: Types.AutoModerationRule) anyerror!void = null,
    auto_moderation_action_execution: ?*const fn (shard: *Shard, action_execution: Types.AutoModerationActionExecution) anyerror!void = null,

    channel_create: ?*const fn (shard: *Shard, chan: Types.Channel) anyerror!void = null,
    channel_update: ?*const fn (shard: *Shard, chan: Types.Channel) anyerror!void = null,
    /// this isn't send when the channel is not relevant to you
    channel_delete: ?*const fn (shard: *Shard, chan: Types.Channel) anyerror!void = null,
    channel_pins_update: ?*const fn (shard: *Shard, chan_pins_update: Types.ChannelPinsUpdate) anyerror!void = null,
    thread_create: ?*const fn (shard: *Shard, thread: Types.Channel) anyerror!void = null,
    thread_update: ?*const fn (shard: *Shard, thread: Types.Channel) anyerror!void = null,
    /// has `id`, `guild_id`, `parent_id`, and `type` fields.
    thread_delete: ?*const fn (shard: *Shard, thread: Types.Partial(Types.Channel)) anyerror!void = null,
    thread_list_sync: ?*const fn (shard: *Shard, data: Types.ThreadListSync) anyerror!void = null,
    thread_member_update: ?*const fn (shard: *Shard, guild_id: Types.ThreadMemberUpdate) anyerror!void = null,
    thread_members_update: ?*const fn (shard: *Shard, thread_data: Types.ThreadMembersUpdate) anyerror!void = null,
    // TODO: implement // guild_audit_log_entry_create: null = null,
    guild_create: ?*const fn (shard: *Shard, guild: Types.Guild) anyerror!void = null,
    guild_create_unavailable: ?*const fn (shard: *Shard, guild: Types.UnavailableGuild) anyerror!void = null,
    guild_update: ?*const fn (shard: *Shard, guild: Types.Guild) anyerror!void = null,
    /// this is not necessarily sent upon deletion of a guild
    /// but from when a user is *removed* therefrom
    guild_delete: ?*const fn (shard: *Shard, guild: Types.UnavailableGuild) anyerror!void = null,
    guild_ban_add: ?*const fn (shard: *Shard, gba: Types.GuildBanAddRemove) anyerror!void = null,
    guild_ban_remove: ?*const fn (shard: *Shard, gbr: Types.GuildBanAddRemove) anyerror!void = null,
    guild_emojis_update: ?*const fn (shard: *Shard, fields: Types.GuildEmojisUpdate) anyerror!void = null,
    guild_stickers_update: ?*const fn (shard: *Shard, fields: Types.GuildStickersUpdate) anyerror!void = null,
    guild_integrations_update: ?*const fn (shard: *Shard, fields: Types.GuildIntegrationsUpdate) anyerror!void = null,
    guild_member_add: ?*const fn (shard: *Shard, guild_id: Types.GuildMemberAdd) anyerror!void = null,
    guild_member_update: ?*const fn (shard: *Shard, fields: Types.GuildMemberUpdate) anyerror!void = null,
    guild_member_remove: ?*const fn (shard: *Shard, user: Types.GuildMemberRemove) anyerror!void = null,
    guild_members_chunk: ?*const fn (shard: *Shard, data: Types.GuildMembersChunk) anyerror!void = null,
    guild_role_create: ?*const fn (shard: *Shard, role: Types.GuildRoleCreate) anyerror!void = null,
    guild_role_delete: ?*const fn (shard: *Shard, role: Types.GuildRoleDelete) anyerror!void = null,
    guild_role_update: ?*const fn (shard: *Shard, role: Types.GuildRoleUpdate) anyerror!void = null,
    guild_scheduled_event_create: ?*const fn (shard: *Shard, s_event: Types.ScheduledEvent) anyerror!void = null,
    guild_scheduled_event_update: ?*const fn (shard: *Shard, s_event: Types.ScheduledEvent) anyerror!void = null,
    guild_scheduled_event_delete: ?*const fn (shard: *Shard, s_event: Types.ScheduledEvent) anyerror!void = null,
    guild_scheduled_event_user_add: ?*const fn (shard: *Shard, data: Types.ScheduledEventUserAdd) anyerror!void = null,
    guild_scheduled_event_user_remove: ?*const fn (shard: *Shard, data: Types.ScheduledEventUserRemove) anyerror!void = null,
    integration_create: ?*const fn (shard: *Shard, guild_id: Types.IntegrationCreateUpdate) anyerror!void = null,
    integration_update: ?*const fn (shard: *Shard, guild_id: Types.IntegrationCreateUpdate) anyerror!void = null,
    integration_delete: ?*const fn (shard: *Shard, guild_id: Types.IntegrationDelete) anyerror!void = null,
    interaction_create: ?*const fn (shard: *Shard, interaction: Types.MessageInteraction) anyerror!void = null,
    invite_create: ?*const fn (shard: *Shard, data: Types.InviteCreate) anyerror!void = null,
    invite_delete: ?*const fn (shard: *Shard, data: Types.InviteDelete) anyerror!void = null,
    message_create: ?*const fn (shard: *Shard, message: Types.Message) anyerror!void = null,
    message_update: ?*const fn (shard: *Shard, message: Types.Message) anyerror!void = null,
    message_delete: ?*const fn (shard: *Shard, log: Types.MessageDelete) anyerror!void = null,
    message_delete_bulk: ?*const fn (shard: *Shard, log: Types.MessageDeleteBulk) anyerror!void = null,
    message_reaction_add: ?*const fn (shard: *Shard, log: Types.MessageReactionAdd) anyerror!void = null,
    message_reaction_remove_all: ?*const fn (shard: *Shard, data: Types.MessageReactionRemoveAll) anyerror!void = null,
    message_reaction_remove: ?*const fn (shard: *Shard, data: Types.MessageReactionRemove) anyerror!void = null,
    message_reaction_remove_emoji: ?*const fn (shard: *Shard, data: Types.MessageReactionRemoveEmoji) anyerror!void = null,
    presence_update: ?*const fn (shard: *Shard, presence: Types.PresenceUpdate) anyerror!void = null,
    stage_instance_create: ?*const fn (shard: *Shard, stage_instance: Types.StageInstance) anyerror!void = null,
    stage_instance_update: ?*const fn (shard: *Shard, stage_instance: Types.StageInstance) anyerror!void = null,
    stage_instance_delete: ?*const fn (shard: *Shard, stage_instance: Types.StageInstance) anyerror!void = null,
    typing_start: ?*const fn (shard: *Shard, data: Types.TypingStart) anyerror!void = null,
    /// remember this is only sent when you change your profile yourself/your bot does
    user_update: ?*const fn (shard: *Shard, user: Types.User) anyerror!void = null,
    // will do these someday, music is rather pointless at this point in time
    // TODO: implement // voice_channel_effect_send: null = null,
    // TODO: implement // voice_state_update: null = null,
    // TODO: implement // voice_server_update: null = null,
    webhooks_update: ?*const fn (shard: *Shard, fields: Types.WebhookUpdate) anyerror!void = null,
    entitlement_create: ?*const fn (shard: *Shard, entitlement: Types.Entitlement) anyerror!void = null,
    entitlement_update: ?*const fn (shard: *Shard, entitlement: Types.Entitlement) anyerror!void = null,
    /// discord claims this is infrequent, therefore not throughoutly tested - Yuzu
    entitlement_delete: ?*const fn (shard: *Shard, entitlement: Types.Entitlement) anyerror!void = null,
    message_poll_vote_add: ?*const fn (shard: *Shard, poll: Types.PollVoteAdd) anyerror!void = null,
    message_poll_vote_remove: ?*const fn (shard: *Shard, poll: Types.PollVoteRemove) anyerror!void = null,

    ready: ?*const fn (shard: *Shard, data: Types.Ready) anyerror!void = null,
    // TODO: implement // resumed: null = null,
    any: ?*const fn (shard: *Shard, data: std.json.Value) anyerror!void = null,
};
