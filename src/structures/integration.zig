const Snowflake = @import("snowflake.zig").Snowflake;
const IntegrationExpireBehaviors = @import("shared.zig").IntegrationExpireBehaviors;
const OAuth2Scope = @import("shared.zig").OAuth2Scope;
const User = @import("user.zig").User;

/// https://discord.com/developers/docs/resources/guild#integration-object-integration-structure
pub const Integration = struct {
    /// Integration Id
    id: Snowflake,
    /// Integration name
    name: []const u8,
    /// Integration type (twitch, youtube, discord, or guild_subscription).
    type: union(enum) {
        twitch,
        youtube,
        discord,
    },
    /// Is this integration enabled
    enabled: ?bool,
    /// Is this integration syncing
    syncing: ?bool,
    /// Role Id that this integration uses for "subscribers"
    role_id: ?Snowflake,
    /// Whether emoticons should be synced for this integration (twitch only currently)
    enable_emoticons: ?bool,
    /// The behavior of expiring subscribers
    expire_behavior: ?IntegrationExpireBehaviors,
    /// The grace period (in days) before expiring subscribers
    expire_grace_period: ?isize,
    /// When this integration was last synced
    synced_at: ?[]const u8,
    /// How many subscribers this integration has
    subscriber_count: ?isize,
    /// Has this integration been revoked
    revoked: ?bool,
    /// User for this integration
    user: ?User,
    /// Integration account information
    account: IntegrationAccount,
    /// The bot/OAuth2 application for discord integrations
    application: ?IntegrationApplication,
    /// the scopes the application has been authorized for
    scopes: []OAuth2Scope,
};

/// https://discord.com/developers/docs/resources/guild#integration-account-object-integration-account-structure
pub const IntegrationAccount = struct {
    /// Id of the account
    id: Snowflake,
    /// Name of the account
    name: []const u8,
};

/// https://discord.com/developers/docs/resources/guild#integration-application-object-integration-application-structure
pub const IntegrationApplication = struct {
    /// The id of the app
    id: Snowflake,
    /// The name of the app
    name: []const u8,
    /// the icon hash of the app
    icon: ?[]const u8,
    /// The description of the app
    description: []const u8,
    /// The bot associated with this application
    bot: ?User,
};

/// https://github.com/discord/discord-api-docs/blob/master/docs/topics/Gateway.md#integration-create-event-additional-fields
pub const IntegrationCreateUpdate = struct {
    /// Integration Id
    id: Snowflake,
    /// Integration name
    name: []const u8,
    /// Integration type (twitch, youtube, discord, or guild_subscription).
    type: union(enum) {
        twitch,
        youtube,
        discord,
    },
    /// Is this integration enabled
    enabled: ?bool,
    /// Is this integration syncing
    syncing: ?bool,
    /// Role Id that this integration uses for "subscribers"
    role_id: ?Snowflake,
    /// Whether emoticons should be synced for this integration (twitch only currently)
    enable_emoticons: ?bool,
    /// The behavior of expiring subscribers
    expire_behavior: ?IntegrationExpireBehaviors,
    /// The grace period (in days) before expiring subscribers
    expire_grace_period: ?isize,
    /// When this integration was last synced
    synced_at: ?[]const u8,
    /// How many subscribers this integration has
    subscriber_count: ?isize,
    /// Has this integration been revoked
    revoked: ?bool,
    /// User for this integration
    user: ?User,
    /// Integration account information
    account: IntegrationAccount,
    /// The bot/OAuth2 application for discord integrations
    application: ?IntegrationApplication,
    /// the scopes the application has been authorized for
    scopes: []OAuth2Scope,
    /// Id of the guild
    guild_id: Snowflake,
};

/// https://github.com/discord/discord-api-docs/blob/master/docs/topics/Gateway.md#integration-delete-event-fields
pub const IntegrationDelete = struct {
    /// Integration id
    id: Snowflake,
    /// Id of the guild
    guild_id: Snowflake,
    /// Id of the bot/OAuth2 application for this discord integration
    application_id: ?Snowflake,
};

/// https://discord.com/developers/docs/topics/gateway#guild-integrations-update
pub const GuildIntegrationsUpdate = struct {
    /// id of the guild whose integrations were updated
    guild_id: Snowflake,
};

/// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-object-interaction-context-types
pub const InteractionContextType = enum {
    /// Interaction can be used within servers
    Guild,
    /// Interaction can be used within DMs with the app's bot user
    BotDm,
    /// Interaction can be used within Group DMs and DMs other than the app's bot user
    PrivateChannel,
};