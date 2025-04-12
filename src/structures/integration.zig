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
        enabled: ?bool = null,
        /// Is this integration syncing
        syncing: ?bool = null,
        /// Role Id that this integration uses for "subscribers"
        role_id: ?Snowflake = null,
        /// Whether emoticons should be synced for this integration (twitch only currently)
        enable_emoticons: ?bool = null,
        /// The behavior of expiring subscribers
        expire_behavior: ?IntegrationExpireBehaviors = null,
        /// The grace period (in days) before expiring subscribers
        expire_grace_period: ?isize = null,
        /// When this integration was last synced
        synced_at: ?[]const u8 = null,
        /// How many subscribers this integration has
        subscriber_count: ?isize = null,
        /// Has this integration been revoked
        revoked: ?bool = null,
        /// User for this integration
        user: ?User = null,
        /// Integration account information
        account: IntegrationAccount,
        /// The bot/OAuth2 application for discord integrations
        application: ?IntegrationApplication = null,
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
        icon: ?[]const u8 = null,
        /// The description of the app
        description: []const u8,
        /// The bot associated with this application
        bot: ?User = null,
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
        enabled: ?bool = null,
        /// Is this integration syncing
        syncing: ?bool = null,
        /// Role Id that this integration uses for "subscribers"
        role_id: ?Snowflake = null,
        /// Whether emoticons should be synced for this integration (twitch only currently)
        enable_emoticons: ?bool = null,
        /// The behavior of expiring subscribers
        expire_behavior: ?IntegrationExpireBehaviors = null,
        /// The grace period (in days) before expiring subscribers
        expire_grace_period: ?isize = null,
        /// When this integration was last synced
        synced_at: ?[]const u8 = null,
        /// How many subscribers this integration has
        subscriber_count: ?isize = null,
        /// Has this integration been revoked
        revoked: ?bool = null,
        /// User for this integration
        user: ?User = null,
        /// Integration account information
        account: IntegrationAccount,
        /// The bot/OAuth2 application for discord integrations
        application: ?IntegrationApplication = null,
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
        application_id: ?Snowflake = null,
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
