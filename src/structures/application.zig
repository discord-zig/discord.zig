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
const ApplicationFlags = @import("shared.zig").ApplicationFlags;
const OAuth2Scope = @import("shared.zig").OAuth2Scope;
const Partial = @import("partial.zig").Partial;
const User = @import("user.zig").User;
const Team = @import("team.zig").Team;
const Guild = @import("guild.zig").Guild;
const AssociativeArray = @import("../utils/json.zig").AssociativeArray;

/// https://discord.com/developers/docs/resources/application#application-object
pub const Application = struct {
    /// The name of the app
    name: []const u8,
    /// The description of the app
    description: []const u8,
    /// An array of rpc origin urls, if rpc is enabled
        rpc_origins: ?[][]const u8 = null,
        /// The url of the app's terms of service
        terms_of_service_url: ?[]const u8 = null,
        /// The url of the app's privacy policy
        privacy_policy_url: ?[]const u8 = null,
        /// The hex encoded key for verification in interactions and the GameSDK's GetTicket
        verify_key: []const u8,
        ///If this application is a game sold on , this field will be the id of the "Game SKU" that is created, if exists
        primary_sku_id: ?Snowflake = null,
        ///If this application is a game sold on , this field will be the URL slug that links to the store page
        slug: ?[]const u8 = null,
        /// The application's public flags
        flags: ?ApplicationFlags = null,
        /// The id of the app
        id: Snowflake,
        /// The icon hash of the app
        icon: ?[]const u8 = null,
        /// When false only app owner can join the app's bot to guilds
        bot_public: bool,
        /// When true the app's bot will only join upon completion of the full oauth2 code grant flow
        bot_require_code_grant: bool,
        /// Partial user object containing info on the owner of the application
        owner: ?Partial(User) = null,
        /// If the application belongs to a team, this will be a list of the members of that team
        team: ?Team = null,
        /// Guild associated with the app. For example, a developer support server.
        guild_id: ?Snowflake = null,
        /// A partial object of the associated guild
        guild: ?Partial(Guild) = null,
        ///If this application is a game sold on , this field will be the hash of the image on store embeds
        cover_image: ?[]const u8 = null,
        /// up to 5 tags describing the content and functionality of the application
        tags: ?[][]const u8 = null,
        /// settings for the application's default in-app authorization link, if enabled
        install_params: ?InstallParams = null,
        // Default scopes and permissions for each supported installation context.
        integration_types_config: ?AssociativeArray(ApplicationIntegrationType, ApplicationIntegrationTypeConfiguration) = null,
        /// the application's default custom authorization link, if enabled
        custom_install_url: ?[]const u8 = null,
        /// the application's role connection verification entry point, which when configured will render the app as a verification method in the guild role verification configuration
        role_connections_verification_url: ?[]const u8 = null,
        /// An approximate count of the app's guild membership.
        approximate_guild_count: ?isize = null,
        /// Approximate count of users that have installed the app.
        approximate_user_install_count: ?isize = null,
        /// Partial user object for the bot user associated with the app
        bot: ?Partial(User) = null,
        /// Array of redirect URIs for the app
        redirect_uris: ?[][]const u8 = null,
        /// Interactions endpoint URL for the app
        interactions_endpoint_url: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/application#application-object-application-integration-type-configuration-object
    pub const ApplicationIntegrationTypeConfiguration = struct {
        ///
        /// Install params for each installation context's default in-app authorization link
        ///
        /// https://discord.com/developers/docs/resources/application#install-params-object-install-params-structure
        ///
        oauth2_install_params: ?InstallParams = null,
    };

    pub const ApplicationIntegrationType = enum(u4) {
        /// App is installable to servers
        GuildInstall = 0,
        /// App is installable to users
        UserInstall = 1,
    };

    pub const InstallParams = struct {
        /// Scopes to add the application to the server with
        scopes: []OAuth2Scope,
        /// Permissions to request for the bot role
        permissions: []const u8,
    };

    pub const ModifyApplication = struct {
        /// Default custom authorization URL for the app, if enabled
        custom_install_url: ?[]const u8 = null,
        /// Description of the app
        description: ?[]const u8 = null,
        /// Role connection verification URL for the app
        role_connections_verification_url: ?[]const u8 = null,
        /// Settings for the app's default in-app authorization link, if enabled
        install_params: ?InstallParams = null,
        /// Default scopes and permissions for each supported installation context.
        integration_types_config: ?ApplicationIntegrationType = null,
        /// App's public flags
        /// @remarks
        /// Only limited intent flags (`GATEWAY_PRESENCE_LIMITED`, `GATEWAY_GUILD_MEMBERS_LIMITED`, and `GATEWAY_MESSAGE_CONTENT_LIMITED`) can be updated via the API.
        flags: ?ApplicationFlags = null,
        /// Icon for the app
        icon: ?[]const u8 = null,
        /// Default rich presence invite cover image for the app
        cover_image: ?[]const u8 = null,
        /// Interactions endpoint URL for the app
        /// @remarks
        /// To update an Interactions endpoint URL via the API, the URL must be valid
        interaction_endpoint_url: ?[]const u8 = null,
        /// List of tags describing the content and functionality of the app (max of 20 characters per tag)
        /// @remarks
        /// There can only be a max of 5 tags
        tags: ?[][]const u8 = null,
        /// Event webhook URL for the app to receive webhook events
        event_webhooks_url: ?[]const u8 = null,
        /// If webhook events are enabled for the app. 1 to disable, and 2 to enable.
        event_webhooks_status: ?ApplicationEventWebhookStatus = null,
        /// List of Webhook event types the app subscribes to
        event_webhooks_types: ?[]WebhookEventType = null,
};

pub const ApplicationEventWebhookStatus = enum(u8) {
    /// Webhook events are disabled by developer
    Disabled = 1,
    /// Webhook events are enabled by developer */
    Enabled = 2,
    /// Webhook events are disabled by Discord, usually due to inactivity */
    DisabledByDiscord = 3,
};

/// https://discord.com/developers/docs/events/webhook-events#event-types
pub const WebhookEventType = union(enum) {
    /// Sent when an app was authorized by a user to a server or their account
    APPLICATION_AUTHORIZED,
    /// Entitlement was created
    ENTITLEMENT_CREATE,
    /// User was added to a Quest (currently unavailable)
    QUEST_USER_ENROLLMENT,
};
