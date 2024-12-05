const Snowflake = @import("snowflake.zig").Snowflake;
const WebhookTypes = @import("shared.zig").WebhookTypes;
const User = @import("user.zig").User;
const Guild = @import("guild.zig").Guild;
const Channel = @import("channel.zig").Channel;
const Partial = @import("partial.zig").Partial;

/// https://discord.com/developers/docs/topics/gateway#webhooks-update-webhook-update-event-fields
pub const WebhookUpdate = struct {
    /// id of the guild
    guild_id: Snowflake,
    /// id of the channel
    channel_id: Snowflake,
};

/// https://discord.com/developers/docs/resources/webhook#webhook-object-webhook-structure
/// TODO: implement
pub const Webhook = null;

pub const IncomingWebhook = struct {
    /// The type of the webhook
    type: WebhookTypes,
    /// The secure token of the webhook (returned for Incoming Webhooks)
    token: ?[]const u8,
    /// The url used for executing the webhook (returned by the webhooks OAuth2 flow)
    url: ?[]const u8,

    /// The id of the webhook
    id: Snowflake,
    /// The guild id this webhook is for
    guild_id: ?Snowflake,
    /// The channel id this webhook is for
    channel_id: Snowflake,
    /// The user this webhook was created by (not returned when getting a webhook with its token)
    user: ?User,
    /// The default name of the webhook
    name: ?[]const u8,
    /// The default user avatar hash of the webhook
    avatar: ?[]const u8,
    /// The bot/OAuth2 application that created this webhook
    application_id: ?Snowflake,
    /// The guild of the channel that this webhook is following (returned for Channel Follower Webhooks)
    source_guild: ?Partial(Guild),
    /// The channel that this webhook is following (returned for Channel Follower Webhooks)
    source_channel: ?Partial(Channel),
};

pub const ApplicationWebhook = struct {
    /// The type of the webhook
    type: WebhookTypes.Application,
    /// The secure token of the webhook (returned for Incoming Webhooks)
    token: ?[]const u8,
    /// The url used for executing the webhook (returned by the webhooks OAuth2 flow)
    url: ?[]const u8,

    /// The id of the webhook
    id: Snowflake,
    /// The guild id this webhook is for
    guild_id: ?Snowflake,
    /// The channel id this webhook is for
    channel_id: ?Snowflake,
    /// The user this webhook was created by (not returned when getting a webhook with its token)
    user: ?User,
    /// The default name of the webhook
    name: ?[]const u8,
    /// The default user avatar hash of the webhook
    avatar: ?[]const u8,
    /// The bot/OAuth2 application that created this webhook
    application_id: ?Snowflake,
    /// The guild of the channel that this webhook is following (returned for Channel Follower Webhooks), field will be absent if the webhook creator has since lost access to the guild where the followed channel resides
    source_guild: ?Partial(Guild),
    /// The channel that this webhook is following (returned for Channel Follower Webhooks), field will be absent if the webhook creator has since lost access to the guild where the followed channel resides
    source_channel: ?Partial(Channel),
};