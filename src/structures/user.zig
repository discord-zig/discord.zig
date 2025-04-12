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

    const PremiumTypes = @import("shared.zig").PremiumTypes;
    const Snowflake = @import("snowflake.zig").Snowflake;
    const Application = @import("application.zig").Application;
    const OAuth2Scope = @import("shared.zig").OAuth2Scope;
    const Integration = @import("integration.zig").Integration;
    const Partial = @import("partial.zig").Partial;
    const Record = @import("../json-helper.zig").Record;

    /// https://discord.com/developers/docs/resources/user#user-object
    pub const User = struct {
        /// The user's username, not unique across the platform
        username: []const u8,
        /// The user's display name, if it is set. For bots, this is the application name
        global_name: ?[]const u8 = null,
        /// The user's chosen language option
        locale: ?[]const u8 = null,
        /// The flags on a user's account
        flags: ?isize = null,
        /// The type of Nitro subscription on a user's account
        premium_type: ?PremiumTypes = null,
        /// The public flags on a user's account
        public_flags: ?isize = null,
        /// the user's banner color encoded as an integer representation of hexadecimal color code
        accent_color: ?isize = null,
        /// The user's id
        id: Snowflake,
        /// The user's discord-tag
        discriminator: []const u8,
        /// The user's avatar hash
        avatar: ?[]const u8 = null,
        /// Whether the user belongs to an OAuth2 application
        bot: ?bool = null,
        ///Whether the user is an Official  System user (part of the urgent message system)
        system: ?bool = null,
        /// Whether the user has two factor enabled on their account
        mfa_enabled: ?bool = null,
        /// Whether the email on this account has been verified
        verified: ?bool = null,
        /// The user's email
        email: ?[]const u8 = null,
        /// the user's banner, or null if unset
        banner: ?[]const u8 = null,
        /// data for the user's avatar decoration
        avatar_decoration_data: ?AvatarDecorationData = null,
        clan: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/user#avatar-decoration-data-object
    pub const AvatarDecorationData = struct {
        /// the avatar decoration hash
        asset: []const u8,
        /// id of the avatar decoration's SKU
        sku_id: Snowflake,
    };

    /// TODO: implement
    pub const TokenExchange = null;

    pub const TokenRevocation = struct {
        /// The access token to revoke
        token: []const u8,
        /// Optional, the type of token you are using for the revocation
        token_type_hint: ?"access_token' | 'refresh_token" = null,
    };

    /// https://discord.com/developers/docs/topics/oauth2#get-current-authorization-information-response-structure
    pub const CurrentAuthorization = struct {
        application: Application,
        /// the scopes the user has authorized the application for
        scopes: []OAuth2Scope,
        /// when the access token expires
        expires: []const u8,
        /// the user who has authorized, if the user has authorized with the `identify` scope
        user: ?User = null,
    };

    /// https://discord.com/developers/docs/resources/user#connection-object-connection-structure
    pub const Connection = struct {
        /// id of the connection account
        id: Snowflake,
        /// the username of the connection account
        name: []const u8,
        /// the service of this connection
        type: ConnectionServiceType,
        /// whether the connection is revoked
        revoked: ?bool = null,
        /// an array of partial server integrations
        integrations: ?[]Partial(Integration) = null,
        /// whether the connection is verified
        verified: bool,
        /// whether friend sync is enabled for this connection
        friend_sync: bool,
        /// whether activities related to this connection will be shown in presence updates
        show_activity: bool,
        /// whether this connection has a corresponding third party OAuth2 token
        two_way_link: bool,
        /// visibility of this connection
        visibility: ConnectionVisibility,
    };

    /// https://discord.com/developers/docs/resources/user#connection-object-services
    pub const ConnectionServiceType = union(enum) {
        @"amazon-music",
        battlenet,
        @"Bungie.net",
        domain,
        ebay,
        epicgames,
        facebook,
        github,
        instagram,
        leagueoflegends,
        paypal,
        playstation,
        reddit,
        riotgames,
        roblox,
        spotify,
        skype,
        steam,
        tiktok,
        twitch,
        twitter,
        xbox,
        youtube,
    };

    //https://discord.com/developers/docs/resources/user#connection-object-visibility-types
    pub const ConnectionVisibility = enum(u4) {
        /// invisible to everyone except the user themselves
        None = 0,
        /// visible to everyone
        Everyone = 1,
    };

    /// https://discord.com/developers/docs/resources/user#application-role-connection-object-application-role-connection-structure
    pub const ApplicationRoleConnection = struct {
        /// the vanity name of the platform a bot has connected (max 50 characters)
        platform_name: ?[]const u8 = null,
        /// the username on the platform a bot has connected (max 100 characters)
        platform_username: ?[]const u8 = null,
        /// object mapping application role connection metadata keys to their stringified value (max 100 characters) for the user on the platform a bot has connected
        metadata: []Record([]const u8),
    };

    pub const ModifyCurrentUser = struct {
        /// user's username, if changed may cause the user's discriminator to be randomized.
        username: ?[]const u8 = null,
        /// if passed, modifies the user's avatar
        avatar: ?[]const u8 = null,
        /// if passed, modifies the user's banner
        banner: ?[]const u8 = null,
};
