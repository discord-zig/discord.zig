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

    const User = @import("user.zig").User;
    const Snowflake = @import("snowflake.zig").Snowflake;
    const ActivityTypes = @import("shared.zig").ActivityTypes;
    const Partial = @import("partial.zig").Partial;

    /// https://discord.com/developers/docs/topics/gateway#get-gateway-bot
    pub const GetGatewayBot = struct {
        /// The WSS URL that can be used for connecting to the gateway
        url: []const u8,
        /// The recommended isize of shards to use when connecting
        shards: isize,
        /// Information on the current session start limit
        session_start_limit: SessionStartLimit,
    };

    /// https://discord.com/developers/docs/topics/gateway#session-start-limit-object
    pub const SessionStartLimit = struct {
        /// The total isize of session starts the current user is allowed
        total: isize,
        /// The remaining isize of session starts the current user is allowed
        remaining: isize,
        /// The isize of milliseconds after which the limit resets
        reset_after: isize,
        /// The isize of identify requests allowed per 5 seconds
        max_concurrency: isize,
    };

    /// https://discord.com/developers/docs/topics/gateway#presence-update
    pub const PresenceUpdate = struct {
        /// Either "idle", "dnd", "online", or "offline"
        status: union(enum) {
            idle,
            dnd,
            online,
            offline,
        },
        /// The user presence is being updated for
        user: Partial(User),
        /// id of the guild
        guild_id: Snowflake,
        /// User's current activities
        activities: []Activity,
        /// User's platform-dependent status
        client_status: ClientStatus,
    };

    /// https://discord.com/developers/docs/topics/gateway-events#activity-object
    pub const Activity = struct {
        /// The activity's name
        name: []const u8,
        /// Activity type
        type: ActivityTypes,
        /// Stream url, is validated when type is 1
        url: ?[]const u8 = null,
        /// Unix timestamp of when the activity was added to the user's session
        created_at: isize,
        /// What the player is currently doing
        details: ?[]const u8 = null,
        /// The user's current party status
        state: ?[]const u8 = null,
        /// Whether or not the activity is an instanced game session
        instance: ?bool = null,
        /// Activity flags `OR`d together, describes what the payload includes
        flags: ?isize = null,
        /// Unix timestamps for start and/or end of the game
        timestamps: ?ActivityTimestamps = null,
        /// Application id for the game
        /// a string
        application_id: ?[]const u8 = null,
        /// The emoji used for a custom status
        emoji: ?ActivityEmoji = null,
        /// Information for the current party of the player
        party: ?ActivityParty = null,
        /// Images for the presence and their hover texts
        assets: ?ActivityAssets = null,
        /// Secrets for Rich Presence joining and spectating
        secrets: ?ActivitySecrets = null,
        /// The custom buttons shown in the Rich Presence (max 2)
        buttons: ?[]ActivityButton = null,
    };

    /// https://discord.com/developers/docs/resources/application#get-application-activity-instance-activity-instance-object
    pub const ActivityInstance = struct {
        /// Application ID
        /// a string
        application_id: []const u8,
        /// Activity Instance ID
        /// a string
        instance_id: []const u8,
        /// Unique identifier for the launch
        /// a string
        launch_id: []const u8,
        /// The Location the instance is runnning in
        location: ActivityLocation,
        /// The IDs of the Users currently connected to the instance
        users: []Snowflake,
    };

    /// https://discord.com/developers/docs/resources/application#get-application-activity-instance-activity-location-object
    pub const ActivityLocation = struct {
        /// The unique identifier for the location
        /// a string
        id: []const u8,
        /// Enum describing kind of location
        kind: ActivityLocationKind,
        /// The id of the Channel
        channel_id: Snowflake,
        /// The id of the Guild
        guild_id: ?Snowflake = null,
    };

    /// https://discord.com/developers/docs/resources/application#get-application-activity-instance-activity-location-kind-enum
    pub const ActivityLocationKind = union(enum) {
        /// The Location is a Guild Channel
        gc,
        /// The Location is a Private Channel, such as a DM or GDM
        pc,
    };

    /// https://discord.com/developers/docs/topics/gateway#client-status-object
    pub const ClientStatus = struct {
        /// The user's status set for an active desktop (Windows, Linux, Mac) application session
        desktop: ?[]const u8 = null,
        /// The user's status set for an active mobile (iOS, Android) application session
        mobile: ?[]const u8 = null,
        /// The user's status set for an active web (browser, bot account) application session
        web: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#activity-object-activity-timestamps
    pub const ActivityTimestamps = struct {
        /// Unix time (in milliseconds) of when the activity started
        start: ?isize = null,
        /// Unix time (in milliseconds) of when the activity ends
        end: ?isize = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#activity-object-activity-emoji
    pub const ActivityEmoji = struct {
        /// The name of the emoji
        name: []const u8,
        /// Whether this emoji is animated
        animated: ?bool = null,
        /// The id of the emoji
        /// a string
        id: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#activity-object-activity-party
    pub const ActivityParty = struct {
        /// Used to show the party's current and maximum size
        size: ?[2]i64 = null,
        /// The id of the party
        id: ?Snowflake = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#activity-object-activity-assets
    pub const ActivityAssets = struct {
        /// Text displayed when hovering over the large image of the activity
        large_text: ?[]const u8 = null,
        /// Text displayed when hovering over the small image of the activity
        small_text: ?[]const u8 = null,
        /// The id for a large asset of the activity, usually a snowflake
        large_image: ?[]const u8 = null,
        /// The id for a small asset of the activity, usually a snowflake
        small_image: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#activity-object-activity-secrets
    pub const ActivitySecrets = struct {
        /// The secret for joining a party
        join: ?[]const u8 = null,
        /// The secret for spectating a game
        spectate: ?[]const u8 = null,
        /// The secret for a specific instanced match
        match: ?[]const u8 = null,
};

/// https://discord.com/developers/docs/topics/gateway#activity-object-activity-buttons
pub const ActivityButton = struct {
    /// The text shown on the button (1-32 characters)
    label: []const u8,
    /// The url opened when clicking the button (1-512 characters)
    url: []const u8,
};
