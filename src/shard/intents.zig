const std = @import("std");
const mem = std.mem;
const json = std.json;

/// https://discord.com/developers/docs/topics/gateway#list-of-intents
pub const GatewayIntents = packed struct {
    pub fn toRaw(self: GatewayIntents) u32 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u32) GatewayIntents {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: mem.Allocator, src: anytype, _: json.ParseOptions) !@This() {
        const value = try json.innerParse(json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: mem.Allocator, src: json.Value, _: json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    ///
    /// - GUILD_CREATE
    /// - GUILD_UPDATE
    /// - GUILD_DELETE
    /// - GUILD_ROLE_CREATE
    /// - GUILD_ROLE_UPDATE
    /// - GUILD_ROLE_DELETE
    /// - CHANNEL_CREATE
    /// - CHANNEL_UPDATE
    /// - CHANNEL_DELETE
    /// - CHANNEL_PINS_UPDATE
    /// - THREAD_CREATE
    /// - THREAD_UPDATE
    /// - THREAD_DELETE
    /// - THREAD_LIST_SYNC
    /// - THREAD_MEMBER_UPDATE
    /// - THREAD_MEMBERS_UPDATE
    /// - STAGE_INSTANCE_CREATE
    /// - STAGE_INSTANCE_UPDATE
    /// - STAGE_INSTANCE_DELETE
    ////
    Guilds: bool = false,
    ///
    /// - GUILD_MEMBER_ADD
    /// - GUILD_MEMBER_UPDATE
    /// - GUILD_MEMBER_REMOVE
    /// - THREAD_MEMBERS_UPDATE
    ///
    /// This is a privileged intent.
    ////
    GuildMembers: bool = false,
    ///
    /// - GUILD_AUDIT_LOG_ENTRY_CREATE
    /// - GUILD_BAN_ADD
    /// - GUILD_BAN_REMOVE
    ////
    GuildModeration: bool = false,
    ///
    /// - GUILD_EMOJIS_UPDATE
    /// - GUILD_STICKERS_UPDATE
    ////
    GuildEmojisAndStickers: bool = false,
    ///
    /// - GUILD_INTEGRATIONS_UPDATE
    /// - INTEGRATION_CREATE
    /// - INTEGRATION_UPDATE
    /// - INTEGRATION_DELETE
    ////
    GuildIntegrations: bool = false,
    ///
    /// - WEBHOOKS_UPDATE
    ////
    GuildWebhooks: bool = false,
    ///
    /// - INVITE_CREATE
    /// - INVITE_DELETE
    ////
    GuildInvites: bool = false,
    ///
    /// - VOICE_STATE_UPDATE
    /// - VOICE_CHANNEL_EFFECT_SEND
    ////
    GuildVoiceStates: bool = false,
    ///
    /// - PRESENCE_UPDATE
    ///
    /// This is a privileged intent.
    ////
    GuildPresences: bool = false,
    ///
    /// - MESSAGE_CREATE
    /// - MESSAGE_UPDATE
    /// - MESSAGE_DELETE
    /// - MESSAGE_DELETE_BULK
    ///
    /// The messages do not contain content by default.
    /// If you want to receive their content too, you need to turn on the privileged `MESSAGE_CONTENT` intent. */
    GuildMessages: bool = false,
    ///
    /// - MESSAGE_REACTION_ADD
    /// - MESSAGE_REACTION_REMOVE
    /// - MESSAGE_REACTION_REMOVE_ALL
    /// - MESSAGE_REACTION_REMOVE_EMOJI
    ////
    GuildMessageReactions: bool = false,
    ///
    /// - TYPING_START
    ////
    GuildMessageTyping: bool = false,
    ///
    /// - CHANNEL_CREATE
    /// - MESSAGE_CREATE
    /// - MESSAGE_UPDATE
    /// - MESSAGE_DELETE
    /// - CHANNEL_PINS_UPDATE
    ////
    DirectMessages: bool = false,
    ///
    /// - MESSAGE_REACTION_ADD
    /// - MESSAGE_REACTION_REMOVE
    /// - MESSAGE_REACTION_REMOVE_ALL
    /// - MESSAGE_REACTION_REMOVE_EMOJI
    ////
    DirectMessageReactions: bool = false,
    ///
    /// - TYPING_START
    ////
    DirectMessageTyping: bool = false,
    ///
    /// This intent will add all content related values to message events.
    ///
    /// This is a privileged intent.
    ////
    MessageContent: bool = false,
    ///
    /// - GUILD_SCHEDULED_EVENT_CREATE
    /// - GUILD_SCHEDULED_EVENT_UPDATE
    /// - GUILD_SCHEDULED_EVENT_DELETE
    /// - GUILD_SCHEDULED_EVENT_USER_ADD this is experimental and unstable.
    /// - GUILD_SCHEDULED_EVENT_USER_REMOVE this is experimental and unstable.
    ////
    GuildScheduledEvents: bool = false,
    _pad: u4 = 0,
    ///
    /// - AUTO_MODERATION_RULE_CREATE
    /// - AUTO_MODERATION_RULE_UPDATE
    /// - AUTO_MODERATION_RULE_DELETE
    ////
    AutoModerationConfiguration: bool = false,
    ///
    /// - AUTO_MODERATION_ACTION_EXECUTION
    ////
    AutoModerationExecution: bool = false,
    _pad2: u3 = 0,
    ///
    /// - MESSAGE_POLL_VOTE_ADD
    /// - MESSAGE_POLL_VOTE_REMOVE
    ////
    GuildMessagePolls: bool = false,
    ///
    /// - MESSAGE_POLL_VOTE_ADD
    /// - MESSAGE_POLL_VOTE_REMOVE
    ////
    DirectMessagePolls: bool = false,
    _pad3: u4 = 0,
};

/// https://discord.com/developers/docs/topics/gateway#list-of-intents
/// alias
pub const Intents = GatewayIntents;
