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
    const Member = @import("member.zig").Member;

    const AllowedMentionsTypes = @import("shared.zig").AllowedMentionsTypes;
    const ChannelTypes = @import("shared.zig").ChannelTypes;
    const OverwriteTypes = @import("shared.zig").OverwriteTypes;
    const ChannelFlags = @import("shared.zig").ChannelFlags;
    const TargetTypes = @import("shared.zig").TargetTypes;
    const VideoQualityModes = @import("shared.zig").VideoQualityModes;
    const SortOrderTypes = @import("shared.zig").SortOrderTypes;
    const User = @import("user.zig").User;
    const ThreadMetadata = @import("thread.zig").ThreadMetadata;
    const ThreadMember = @import("thread.zig").ThreadMember;
    const ForumLayout = @import("shared.zig").ForumLayout;

    /// https://discord.com/developers/docs/resources/channel#allowed-mentions-object
    pub const AllowedMentions = struct {
        /// An array of allowed mention types to parse from the content.
        parse: ?[]AllowedMentionsTypes = null,
        /// For replies, whether to mention the author of the message being replied to (default false)
        replied_user: ?bool = null,
        /// Array of role_ids to mention (Max size of 100)
        roles: ?[][]const u8 = null,
        /// Array of user_ids to mention (Max size of 100)
        users: ?[][]const u8 = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#typing-start
    pub const TypingStart = struct {
        /// Unix time (in seconds) of when the user started typing
        timestamp: isize,
        /// id of the channel
        channel_id: Snowflake,
        /// id of the guild
        guild_id: ?Snowflake = null,
        /// id of the user
        user_id: Snowflake,
        /// The member who started typing if this happened in a guild
        member: ?Member = null,
    };

    /// https://discord.com/developers/docs/resources/channel#channel-object
    pub const Channel = struct {
        /// The id of the channel
        id: Snowflake,
        /// The type of channel
        type: ChannelTypes,
        /// The id of the guild
        guild_id: ?Snowflake = null,
        /// Sorting position of the channel (channels with the same position are sorted by id)
        position: ?isize = null,
        /// Explicit permission overwrites for members and roles
        permission_overwrites: ?[]Overwrite = null,
        /// The name of the channel (1-100 characters)
        name: ?[]const u8 = null,
        /// The channel topic (0-4096 characters for GUILD_FORUM channels, 0-1024 characters for all others)
        topic: ?[]const u8 = null,
        /// Whether the channel is nsfw
        nsfw: ?bool = null,
        /// The id of the last message sent in this channel (may not point to an existing or valid message)
        last_message_id: ?Snowflake = null,
        /// The bitrate (in bits) of the voice or stage channel
        bitrate: ?isize = null,
        /// The user limit of the voice or stage channel
        user_limit: ?isize = null,
        /// Amount of seconds a user has to wait before sending another message (0-21600); bots, as well as users with the permission `manage_messages` or `manage_channel`, are unaffected
        rate_limit_per_user: ?isize = null,
        /// the recipients of the DM
        recipients: ?[]User = null,
        /// icon hash of the group DM
        icon: ?[]const u8 = null,
        /// Id of the creator of the thread
        owner_id: ?Snowflake = null,
        /// Application id of the group DM creator if it is bot-created
        application_id: ?Snowflake = null,
        /// For group DM channels: whether the channel is managed by an application via the `gdm.join` OAuth2 scope.,
        managed: ?bool = null,
        /// For guild channels: Id of the parent category for a channel (each parent category can contain up to 50 channels), for threads: id of the text channel this thread was created,
        parent_id: ?Snowflake = null,
        /// When the last pinned message was pinned. This may be null in events such as GUILD_CREATE when a message is not pinned.
        last_pin_timestamp: ?[]const u8 = null,
        /// Voice region id for the voice or stage channel, automatic when set to null
        rtc_region: ?[]const u8 = null,
        /// The camera video quality mode of the voice channel, 1 when not present
        video_quality_mode: ?VideoQualityModes = null,
        /// An approximate count of messages in a thread, stops counting at 50
        message_count: ?isize = null,
        /// An approximate count of users in a thread, stops counting at 50
        member_count: ?isize = null,
        /// Thread-specific fields not needed by other channels
        thread_metadata: ?ThreadMetadata = null,
        /// Thread member object for the current user, if they have joined the thread, only included on certain API endpoints
        member: ?ThreadMember = null,
        /// Default duration for newly created threads, in minutes, to automatically archive the thread after recent activity, can be set to: 60, 1440, 4320, 10080,
        default_auto_archive_duration: ?isize = null,
        /// computed permissions for the invoking user in the channel, including overwrites, only included when part of the resolved data received on a slash command interaction. This does not include implicit permissions, which may need to be checked separately.
        permissions: ?[]const u8 = null,
        /// The flags of the channel
        flags: ?ChannelFlags = null,
        /// isize of messages ever sent in a thread, it's similar to `message_count` on message creation, but will not decrement the isize when a message is deleted
        total_message_sent: ?isize = null,
        /// The set of tags that can be used in a GUILD_FORUM channel
        available_tags: ?[]ForumTag = null,
        /// The IDs of the set of tags that have been applied to a thread in a GUILD_FORUM channel
        applied_tags: ?[][]const u8 = null,
        /// the emoji to show in the add reaction button on a thread in a GUILD_FORUM channel
        default_reaction_emoji: ?DefaultReactionEmoji = null,
        /// the initial rate_limit_per_user to set on newly created threads in a channel. this field is copied to the thread at creation time and does not live update.
        default_thread_rate_limit_per_user: ?isize = null,
        /// the default sort order type used to order posts in GUILD_FORUM channels. Defaults to null, which indicates a preferred sort order hasn't been set by a channel admin
        default_sort_order: ?SortOrderTypes = null,
        /// the default forum layout view used to display posts in `GUILD_FORUM` channels. Defaults to `0`, which indicates a layout view has not been set by a channel admin
        default_forum_layout: ?ForumLayout = null,
        /// When a thread is created this will be true on that channel payload for the thread.
        newly_created: ?bool = null,
    };

    /// https://discord.com/developers/docs/resources/guild#welcome-screen-object-welcome-screen-structure
    pub const WelcomeScreen = struct {
        /// The server description shown in the welcome screen
        description: ?[]const u8 = null,
        /// The channels shown in the welcome screen, up to 5
        welcome_channels: []WelcomeScreenChannel,
    };

    /// https://discord.com/developers/docs/resources/guild#welcome-screen-object-welcome-screen-channel-structure
    pub const WelcomeScreenChannel = struct {
        /// The description shown for the channel
        description: []const u8,
        /// The channel's id
        channel_id: Snowflake,
        /// The emoji id, if the emoji is custom
        emoji_id: ?Snowflake = null,
        /// The emoji name if custom, the unicode character if standard, or `null` if no emoji is set
        emoji_name: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/stage-instance#auto-closing-stage-instance-structure
    pub const StageInstance = struct {
        /// The topic of the Stage instance (1-120 characters)
        topic: []const u8,
        /// The id of this Stage instance
        id: Snowflake,
        /// The guild id of the associated Stage channel
        guild_id: Snowflake,
        /// The id of the associated Stage channel
        channel_id: Snowflake,
        /// The id of the scheduled event for this Stage instance
        guild_scheduled_event_id: ?Snowflake = null,
    };

    pub const Overwrite = struct {
        /// Either 0 (role) or 1 (member)
        type: OverwriteTypes,
        /// Role or user id
        id: Snowflake,
        /// Permission bit set
        allow: ?[]const u8 = null,
        /// Permission bit set
        deny: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/channel#followed-channel-object
    pub const FollowedChannel = struct {
        /// Source message id
        channel_id: Snowflake,
        /// Created target webhook id
        webhook_id: Snowflake,
    };

    pub const ForumTag = struct {
        /// The id of the tag
        id: Snowflake,
        /// The name of the tag (0-20 characters)
        name: []const u8,
        /// Whether this tag can only be added to or removed from threads by a member with the MANAGE_THREADS permission
        moderated: bool,
        /// The id of a guild's custom emoji At most one of emoji_id and emoji_name may be set.
        emoji_id: Snowflake,
        /// The unicode character of the emoji
        emoji_name: ?[]const u8 = null,
    };

    pub const DefaultReactionEmoji = struct {
        /// The id of a guild's custom emoji
        emoji_id: Snowflake,
        /// The unicode character of the emoji
        emoji_name: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
    pub const ModifyGuildChannelPositions = struct {
        /// Channel id
        id: Snowflake,
        /// Sorting position of the channel (channels with the same position are sorted by id)
        position: ?isize = null,
        /// Syncs the permission overwrites with the new parent, if moving to a new category
        lock_positions: ?bool = null,
        /// The new parent ID for the channel that is moved
        parent_id: ?Snowflake = null,
    };

    pub const CreateChannelInvite = struct {
        /// Duration of invite in seconds before expiry, or 0 for never. Between 0 and 604800 (7 days). Default: 86400 (24 hours)
        max_age: ?isize = null,
        /// Max number of users or 0 for unlimited. Between 0 and 100. Default: 0
        max_uses: ?isize = null,
        /// Whether this invite only grants temporary membership. Default: false
        temporary: ?bool = null,
        /// If true, don't try to reuse similar invite (useful for creating many unique one time use invites). Default: false
        unique: ?bool = null,
        /// The type of target for this voice channel invite
        target_type: ?TargetTypes = null,
        /// The id of the user whose stream to display for this invite, required if `target_type` is 1, the user must be streaming in the channel
        target_user_id: ?Snowflake = null,
        /// The id of the embedded application to open for this invite, required if `target_type` is 2, the application must have the `EMBEDDED` flag
        target_application_id: ?Snowflake = null,
};
