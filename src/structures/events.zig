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
    const MemberWithUser = @import("member.zig").MemberWithUser;
    const PresenceUpdate = @import("gateway.zig").PresenceUpdate;
    const User = @import("user.zig").User;
    const Attachment = @import("attachment.zig").Attachment;
    const Role = @import("role.zig").Role;
    const Application = @import("application.zig").Application;
    const AvatarDecorationData = @import("user.zig").AvatarDecorationData;
    const SkuFlags = @import("shared.zig").SkuFlags;
    const ApplicationFlags = @import("shared.zig").ApplicationFlags;
    const TargetTypes = @import("shared.zig").TargetTypes;
    const ChannelTypes = @import("shared.zig").ChannelTypes;
    const MessageFlags = @import("shared.zig").MessageFlags;
    const OverwriteTypes = @import("shared.zig").OverwriteTypes;
    const Emoji = @import("emoji.zig").Emoji;
    const Channel = @import("channel.zig").Channel;
    const Overwrite = @import("channel.zig").Overwrite;
    const ThreadMember = @import("thread.zig").ThreadMember;
    const Embed = @import("embed.zig").Embed;
    const WelcomeScreenChannel = @import("channel.zig").WelcomeScreenChannel;
    const AllowedMentions = @import("channel.zig").AllowedMentions;
    const MessageComponent = @import("component.zig").MessageComponent;
    const Sticker = @import("sticker.zig").Sticker;
    const Partial = @import("partial.zig").Partial;
    const ReactionType = @import("message.zig").ReactionType;
    const Team = @import("team.zig").Team;
    const VideoQualityModes = @import("shared.zig").VideoQualityModes;
    const Guild = @import("guild.zig").Guild;
    const SortOrderTypes = @import("shared.zig").SortOrderTypes;
    const InstallParams = @import("application.zig").InstallParams;
    const ForumLayout = @import("shared.zig").ForumLayout;

    /// https://discord.com/developers/docs/topics/gateway#guild-members-chunk
    pub const GuildMembersChunk = struct {
        /// The id of the guild
        guild_id: Snowflake,
        /// Set of guild members
        members: []MemberWithUser,
        /// The chunk index in the expected chunks for this response (0 <= chunk_index < chunk_count)
        chunk_index: isize,
        /// The total isize of expected chunks for this response
        chunk_count: isize,
        /// If passing an invalid id to `REQUEST_GUILD_MEMBERS`, it will be returned here
        not_found: ?[][]const u8 = null,
        /// If passing true to `REQUEST_GUILD_MEMBERS`, presences of the returned members will be here
        presences: ?[]PresenceUpdate = null,
        /// The nonce used in the Guild Members Request
        nonce: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#channel-pins-update
    pub const ChannelPinsUpdate = struct {
        /// The id of the guild
        guild_id: ?Snowflake = null,
        /// The id of the channel
        channel_id: Snowflake,
        /// The time at which the most recent pinned message was pinned
        last_pin_timestamp: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#guild-role-delete
    pub const GuildRoleDelete = struct {
        /// id of the guild
        guild_id: Snowflake,
        /// id of the role
        role_id: Snowflake,
    };

    /// https://discord.com/developers/docs/topics/gateway#guild-ban-add
    pub const GuildBanAddRemove = struct {
        /// id of the guild
        guild_id: Snowflake,
        /// The banned user
        user: User,
    };

    /// https://discord.com/developers/docs/topics/gateway#message-reaction-remove
    pub const MessageReactionRemove = struct {
        /// The id of the user
        user_id: Snowflake,
        /// The id of the channel
        channel_id: Snowflake,
        /// The id of the message
        message_id: Snowflake,
        /// The id of the guild
        guild_id: ?Snowflake = null,
        /// The emoji used to react
        emoji: Partial(Emoji),
        /// The id of the author of this message
        message_author_id: ?Snowflake = null,
        /// true if this is a super-reaction
        burst: bool,
        /// The type of reaction
        type: ReactionType,
    };

    /// https://discord.com/developers/docs/events/gateway-events#message-reaction-add
    pub const MessageReactionAdd = struct {
        /// The id of the user
        user_id: Snowflake,
        /// The id of the channel
        channel_id: Snowflake,
        /// The id of the message
        message_id: Snowflake,
        /// The id of the guild
        guild_id: ?Snowflake = null,
        /// The member who reacted if this happened in a guild
        member: ?MemberWithUser = null,
        /// The emoji used to react
        emoji: Partial(Emoji),
        /// The id of the author of this message
        message_author_id: ?Snowflake = null,
        /// true if this is a super-reaction
        burst: bool,
        /// Colors used for super-reaction animation in "#rrggbb" format
        burst_colors: ?[][]const u8 = null,
        /// The type of reaction
        type: ReactionType,
    };

    /// https://discord.com/developers/docs/topics/gateway#voice-server-update
    pub const VoiceServerUpdate = struct {
        /// Voice connection token
        token: []const u8,
        /// The guild this voice server update is for
        guild_id: Snowflake,
        /// The voice server host
        endpoint: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/topics/gateway-events#voice-channel-effect-send-voice-channel-effect-send-event-fields
    pub const VoiceChannelEffectSend = struct {
        /// ID of the channel the effect was sent in
        channel_id: Snowflake,
        /// ID of the guild the effect was sent in
        guild_id: Snowflake,
        /// ID of the user who sent the effect
        user_id: Snowflake,
        /// The emoji sent, for emoji reaction and soundboard effects
        emoji: ?Emoji = null,
        /// The type of emoji animation, for emoji reaction and soundboard effects
        animation_type: ?VoiceChannelEffectAnimationType = null,
        /// The ID of the emoji animation, for emoji reaction and soundboard effects
        animation_id: ?isize = null,
        /// The ID of the soundboard sound, for soundboard effects
        sound_id: union {
            string: ?[]const u8,
            integer: isize,
        },
        /// The volume of the soundboard sound, from 0 to 1, for soundboard effects
        sound_volume: ?isize = null,
    };

    /// https://discord.com/developers/docs/topics/gateway-events#voice-channel-effect-send-animation-types
    pub const VoiceChannelEffectAnimationType = enum {
        /// A fun animation, sent by a Nitro subscriber
        Premium,
        /// The standard animation
        Basic,
    };

    /// https://discord.com/developers/docs/topics/gateway#invite-create
    pub const InviteCreate = struct {
        /// The channel the invite is for
        channel_id: Snowflake,
        /// The unique invite code
        code: []const u8,
        /// The time at which the invite was created
        created_at: []const u8,
        /// The guild of the invite
        guild_id: ?Snowflake = null,
        /// The user that created the invite
        inviter: ?User = null,
        /// How long the invite is valid for (in seconds)
        max_age: isize,
        /// The maximum isize of times the invite can be used
        max_uses: isize,
        /// The type of target for this voice channel invite
        target_type: TargetTypes,
        /// The target user for this invite
        target_user: ?User = null,
        /// The embedded application to open for this voice channel embedded application invite
        target_application: ?Partial(Application) = null,
        /// Whether or not the invite is temporary (invited users will be kicked on disconnect unless they're assigned a role)
        temporary: bool,
        /// How many times the invite has been used (always will be 0)
        uses: isize,
    };

    /// https://discord.com/developers/docs/topics/gateway#hello
    pub const Hello = struct {
        /// The interval (in milliseconds) the client should heartbeat with
        heartbeat_interval: isize,
    };

    /// https://discord.com/developers/docs/topics/gateway#ready
    pub const Ready = struct {
        /// Gateway version
        v: isize,
        /// Information about the user including email
        user: User,
        /// The guilds the user is in
        guilds: []UnavailableGuild,
        /// Used for resuming connections
        session_id: []const u8,
        /// Gateway url for resuming connections
        resume_gateway_url: []const u8,
        /// The shard information associated with this session, if sent when identifying
        shard: ?[2]isize = null,
        /// Contains id and flags, only sent to bots
        application: ?struct {
            flags: ApplicationFlags,
            id: Snowflake,
        },
    };

    /// https://discord.com/developers/docs/resources/guild#unavailable-guild-object
    pub const UnavailableGuild = struct {
        unavailable: ?bool = null,
        id: Snowflake,
    };

    /// https://discord.com/developers/docs/events/gateway-events#message-delete-bulk
    pub const MessageDeleteBulk = struct {
        /// The ids of the messages
        ids: []Snowflake,
        /// The id of the channel
        channel_id: Snowflake,
        /// The id of the guild
        guild_id: ?Snowflake = null,
    };

    /// https://discord.com/developers/docs/resources/template#template-object-template-structure
    pub const Template = struct {
        /// The template code (unique Id)
        code: []const u8,
        /// Template name
        name: []const u8,
        /// The description for the template
        description: ?[]const u8 = null,
        /// isize of times this template has been used
        usage_count: isize,
        /// The Id of the user who created the template
        creator_id: Snowflake,
        /// The user who created the template
        creator: User,
        /// When this template was created
        created_at: []const u8,
        /// When this template was last synced to the source guild
        updated_at: []const u8,
        /// The Id of the guild this template is based on
        source_guild_id: Snowflake,
        /// The guild snapshot this template contains
        serialized_source_guild: TemplateSerializedSourceGuild,
        is_dirty: ?bool = null,
    };

    pub const TemplateSerializedSourceGuild = null;

    /// https://discord.com/developers/docs/topics/gateway#guild-member-add
    pub const GuildMemberAdd = struct {
        /// Whether the user is deafened in voice channels
        deaf: ?bool = null,
        /// Whether the user is muted in voice channels
        mute: ?bool = null,
        /// Whether the user has not yet passed the guild's Membership Screening requirements
        pending: ?bool = null,
        /// This users guild nickname
        nick: ?[]const u8 = null,
        /// The members custom avatar for this server.
        avatar: ?[]const u8 = null,
        /// Array of role object ids
        roles: [][]const u8,
        /// When the user joined the guild
        joined_at: []const u8,
        /// When the user started boosting the guild
        premium_since: ?[]const u8 = null,
        /// The permissions this member has in the guild. Only present on interaction events and OAuth2 current member fetch.
        permissions: ?[]const u8 = null,
        /// when the user's timeout will expire and the user will be able to communicate in the guild again (set null to remove timeout), null or a time in the past if the user is not timed out
        communication_disabled_until: ?[]const u8 = null,
        /// Guild member flags
        flags: isize,
        /// data for the member's guild avatar decoration
        avatar_decoration_data: ?AvatarDecorationData = null,
        /// The user object for this member
        user: User,
        /// id of the guild
        guild_id: Snowflake,
    };

    /// https://discord.com/developers/docs/events/gateway-events#message-delete
    pub const MessageDelete = struct {
        /// The id of the message
        id: Snowflake,
        /// The id of the channel
        channel_id: Snowflake,
        /// The id of the guild
        guild_id: ?Snowflake = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#thread-members-update-thread-members-update-event-fields
    pub const ThreadMembersUpdate = struct {
        /// The id of the thread
        id: Snowflake,
        /// The id of the guild
        guild_id: Snowflake,
        /// The users who were added to the thread
        added_members: ?[]ThreadMember = null,
        /// The id of the users who were removed from the thread
        removed_member_ids: ?[][]const u8 = null,
        /// the approximate isize of members in the thread, capped at 50
        member_count: isize,
    };

    /// https://discord.com/developers/docs/topics/gateway#thread-member-update
    pub const ThreadMemberUpdate = struct {
        /// The id of the thread
        id: Snowflake,
        /// The id of the guild
        guild_id: Snowflake,
        /// The timestamp when the bot joined this thread.
        joined_at: []const u8,
        /// The flags this user has for this thread. Not useful for bots.
        flags: isize,
    };

    /// https://discord.com/developers/docs/topics/gateway#guild-role-create
    pub const GuildRoleCreate = struct {
        /// The id of the guild
        guild_id: Snowflake,
        /// The role created
        role: Role,
    };

    /// https://discord.com/developers/docs/topics/gateway#guild-emojis-update
    pub const GuildEmojisUpdate = struct {
        /// id of the guild
        guild_id: Snowflake,
        /// Array of emojis
        emojis: []Emoji,
    };

    /// https://discord.com/developers/docs/topics/gateway-events#guild-stickers-update
    pub const GuildStickersUpdate = struct {
        /// id of the guild
        guild_id: Snowflake,
        /// Array of sticker
        stickers: []Sticker,
    };

    /// https://discord.com/developers/docs/topics/gateway#guild-member-update
    pub const GuildMemberUpdate = struct {
        /// The id of the guild
        guild_id: Snowflake,
        /// User role ids
        roles: [][]const u8,
        /// The user
        user: User,
        /// Nickname of the user in the guild
        nick: ?[]const u8 = null,
        /// the member's [guild avatar hash](https://discord.com/developers/docs/reference#image-formatting)
        avatar: []const u8,
        /// When the user joined the guild
        joined_at: []const u8,
        /// When the user starting boosting the guild
        premium_since: ?[]const u8 = null,
        /// whether the user is deafened in voice channels
        deaf: ?bool = null,
        /// whether the user is muted in voice channels
        mute: ?bool = null,
        /// Whether the user has not yet passed the guild's Membership Screening requirements
        pending: ?bool = null,
        /// when the user's [timeout](https://support.discord.com/hc/en-us/articles/4413305239191-Time-Out-FAQ) will expire and the user will be able to communicate in the guild again, null or a time in the past if the user is not timed out. Will throw a 403 error if the user has the ADMINISTRATOR permission or is the owner of the guild
        communication_disabled_until: ?[]const u8 = null,
        /// Data for the member's guild avatar decoration
        avatar_decoration_data: ?AvatarDecorationData = null,
        /// Guild member flags
        flags: ?isize = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#message-reaction-remove-all
    pub const MessageReactionRemoveAll = struct {
        channel_id: Snowflake,
        message_id: Snowflake,
        guild_id: ?Snowflake = null,
    };

    /// https://discord.com/developers/docs/topics/gateway#guild-role-update
    pub const GuildRoleUpdate = struct {
        /// The id of the guild
        guild_id: Snowflake,
        /// The role updated
        role: Role,
    };

    pub const ScheduledEventUserAdd = struct {
        /// id of the guild scheduled event
        guild_scheduled_event_id: Snowflake,
        /// id of the user
        user_id: Snowflake,
        /// id of the guild
        guild_id: Snowflake,
    };

    /// https://discord.com/developers/docs/topics/gateway#message-reaction-remove-emoji
    pub const MessageReactionRemoveEmoji = struct {
        channel_id: Snowflake,
        message_id: Snowflake,
        guild_id: ?Snowflake = null,
        emoji: Emoji,
    };

    /// https://discord.com/developers/docs/topics/gateway#guild-member-remove
    pub const GuildMemberRemove = struct {
        /// The id of the guild
        guild_id: Snowflake,
        /// The user who was removed
        user: User,
    };

    /// https://discord.com/developers/docs/resources/guild#ban-object
    pub const Ban = struct {
        /// The reason for the ban
        reason: ?[]const u8 = null,
        /// The banned user
        user: User,
    };

    pub const ScheduledEventUserRemove = struct {
        /// id of the guild scheduled event
        guild_scheduled_event_id: Snowflake,
        /// id of the user
        user_id: Snowflake,
        /// id of the guild
        guild_id: Snowflake,
    };

    /// https://discord.com/developers/docs/topics/gateway#invite-delete
    pub const InviteDelete = struct {
        /// The channel of the invite
        channel_id: Snowflake,
        /// The guild of the invite
        guild_id: ?Snowflake = null,
        /// The unique invite code
        code: []const u8,
    };

    /// https://discord.com/developers/docs/resources/voice#voice-region-object-voice-region-structure
    pub const VoiceRegion = struct {
        /// Unique Id for the region
        id: Snowflake,
        /// Name of the region
        name: []const u8,
        /// true for a single server that is closest to the current user's client
        optimal: bool,
        /// Whether this is a deprecated voice region (avoid switching to these)
        deprecated: bool,
        /// Whether this is a custom voice region (used for events/etc)
        custom: bool,
    };

    pub const GuildWidgetSettings = struct {
        /// whether the widget is enabled
        enabled: bool,
        /// the widget channel id
        channel_id: ?Snowflake = null,
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

    pub const ModifyChannel = struct {
        /// 1-100 character channel name
        name: ?[]const u8 = null,
        /// The type of channel; only conversion between text and news is supported and only in guilds with the "NEWS" feature
        type: ?ChannelTypes = null,
        /// The position of the channel in the left-hand listing
        position: ?isize = null,
        /// 0-1024 character channel topic
        topic: ?[]const u8 = null,
        /// Whether the channel is nsfw
        nsfw: ?bool = null,
        /// Amount of seconds a user has to wait before sending another message (0-21600); bots, as well as users with the permission `manage_messages` or `manage_channel`, are unaffected
        rate_limit_per_user: ?isize = null,
        /// The bitrate (in bits) of the voice channel; 8000 to 96000 (128000 for VIP servers)
        bitrate: ?isize = null,
        /// The user limit of the voice channel; 0 refers to no limit, 1 to 99 refers to a user limit
        user_limit: ?isize = null,
        /// Channel or category-specific permissions
        permission_overwrites: ?[]Overwrite = null,
        /// Id of the new parent category for a channel
        parent_id: ?Snowflake = null,
        /// Voice region id for the voice channel, automatic when set to null
        rtc_region: ?[]const u8 = null,
        /// The camera video quality mode of the voice channel
        video_quality_mode: ?VideoQualityModes = null,
        /// Whether the thread is archived
        archived: ?bool = null,
        /// Duration in minutes to automatically archive the thread after recent activity
        auto_archive_duration: ?isize = null,
        /// When a thread is locked, only users with `MANAGE_THREADS` can unarchive it
        locked: ?bool = null,
        /// whether non-moderators can add other non-moderators to a thread; only available on private threads
        invitable: ?bool = null,
        /// The set of tags that can be used in a GUILD_FORUM channel
        available_tags: []struct {
            /// The id of the tag
            id: Snowflake,
            /// The name of the tag (0-20 characters)
            name: []const u8,
            /// Whether this tag can only be added to or removed from threads by a member with the MANAGE_THREADS permission
            moderated: bool,
            /// The id of a guild's custom emoji At most one of emoji_id and emoji_name may be set.
            emoji_id: Snowflake,
            /// The unicode character of the emoji
            emoji_name: []const u8,
        },
        /// The IDs of the set of tags that have been applied to a thread in a GUILD_FORUM channel; limited to 5
        applied_tags: ?[][]const u8 = null,
        /// the emoji to show in the add reaction button on a thread in a GUILD_FORUM channel
        default_reaction_emoji: ?struct {
            /// The id of a guild's custom emoji
            emoji_id: Snowflake,
            /// The unicode character of the emoji
        emoji_name: ?[]const u8 = null,
        },
        /// the initial rate_limit_per_user to set on newly created threads in a channel. this field is copied to the thread at creation time and does not live update.
        default_thread_rate_limit_per_user: ?isize = null,
        /// the default sort order type used to order posts in forum channels
        default_sort_order: ?SortOrderTypes = null,
        /// the default forum layout view used to display posts in `GUILD_FORUM` channels. Defaults to `0`, which indicates a layout view has not been set by a channel admin
        default_forum_layout: ?ForumLayout = null,
    };

    /// https://discord.com/developers/docs/resources/emoji#create-guild-emoji
    pub const CreateGuildEmoji = struct {
        /// Name of the emoji
        name: []const u8,
        ///The 128x128 emoji image. Emojis and animated emojis have a maximum file size of 256kb. Attempting to upload an emoji larger than this limit will fail and return 400 Bad Request and an error message, but not a JSON status code. If a URL is provided to the image parameter, eno will automatically convert it to a base64 []const u8 internally.
        image: []const u8,
        /// Roles allowed to use this emoji
        roles: ?[][]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
    pub const ModifyGuildEmoji = struct {
        /// Name of the emoji
        name: ?[]const u8 = null,
        /// Roles allowed to use this emoji
        roles: ?[][]const u8 = null,
    };

    pub const CreateGuildChannel = struct {
        /// Channel name (1-100 characters)
        name: []const u8,
        /// The type of channel
        type: ?ChannelTypes = null,
        /// Channel topic (0-1024 characters)
        topic: ?[]const u8 = null,
        /// The bitrate (in bits) of the voice channel (voice only)
        bitrate: ?isize = null,
        /// The user limit of the voice channel (voice only)
        user_limit: ?isize = null,
        /// Amount of seconds a user has to wait before sending another message (0-21600); bots, as well as users with the permission `manage_messages` or `manage_channel`, are unaffected
        rate_limit_per_user: ?isize = null,
        /// Sorting position of the channel
        position: ?isize = null,
        /// The channel's permission overwrites
        permission_overwrites: ?[]Overwrite = null,
        /// Id of the parent category for a channel
        parent_id: ?Snowflake = null,
        /// Whether the channel is nsfw
        nsfw: ?bool = null,
        /// Default duration (in minutes) that clients (not the API) use for newly created threads in this channel, to determine when to automatically archive the thread after the last activity
        default_auto_archive_duration: ?isize = null,
        /// Emoji to show in the add reaction button on a thread in a forum channel
        default_reaction_emoji: ?DefaultReactionEmoji = null,
        /// Set of tags that can be used in a forum channel
        available_tags: ?[]ForumTag = null,
        /// the default sort order type used to order posts in forum channels
        default_sort_order: ?SortOrderTypes = null,
    };

    pub const CreateMessage = struct {
        attachments: []Partial(Attachment),
        /// The message contents (up to 2000 characters)
        content: ?[]const u8 = null,
        /// Can be used to verify a message was sent (up to 25 characters). Value will appear in the Message Create event.
        nonce: ?union(enum) {
            string: ?[]const u8,
            integer: isize,
        },
        /// true if this is a TTS message
        tts: ?bool = null,
        /// Embedded `rich` content (up to 6000 characters)
        embeds: ?[]Embed = null,
        /// Allowed mentions for the message
        allowed_mentions: ?AllowedMentions = null,
        /// Include to make your message a reply
        message_reference: ?struct {
            /// id of the originating message
        message_id: ?Snowflake = null,
            ///
            /// id of the originating message's channel
            /// Note: `channel_id` is optional when creating a reply, but will always be present when receiving an event/response that includes this data model.,
            ///
        channel_id: ?Snowflake = null,
            /// id of the originating message's guild
        guild_id: ?Snowflake = null,
            /// When sending, whether to error if the referenced message doesn't exist instead of sending as a normal (non-reply) message, default true
            fail_if_not_exists: bool,
        },
        /// The components you would like to have sent in this message
        components: ?[]MessageComponent = null,
        /// IDs of up to 3 stickers in the server to send in the message
        stickerIds: ?[][]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
    pub const ModifyGuildWelcomeScreen = struct {
        /// Whether the welcome screen is enabled
        enabled: ?bool = null,
        /// Channels linked in the welcome screen and their display options
        welcome_screen: ?[]WelcomeScreenChannel = null,
        /// The server description to show in the welcome screen
        description: ?[]const u8 = null,
    };

    pub const FollowAnnouncementChannel = struct {
        /// The id of the channel to send announcements to.
        webhook_channel_id: Snowflake,
    };

    pub const EditChannelPermissionOverridesOptions = struct {
        /// Permission bit set
        allow: []const u8,
        /// Permission bit set
        deny: []const u8,
        /// Either 0 (role) or 1 (member)
        type: OverwriteTypes,
    };

    /// https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
    pub const ModifyGuildChannelPositions = struct {
        /// Channel id
        id: Snowflake,
        /// Sorting position of the channel
        position: ?isize = null,
        /// Syncs the permission overwrites with the new parent, if moving to a new category
        lock_positions: ?bool = null,
        /// The new parent ID for the channel that is moved
        parent_id: ?Snowflake = null,
    };

    pub const CreateWebhook = struct {
        /// Name of the webhook (1-80 characters)
        name: []const u8,
        /// Image url for the default webhook avatar
        avatar: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/channel#start-thread-in-forum-channel
    pub const CreateForumPostWithMessage = struct {
        /// 1-100 character channel name
        name: []const u8,
        /// duration in minutes to automatically archive the thread after recent activity, can be set to: 60, 1440, 4320, 10080,
        auto_archive_duration: ?isize = null,
        /// amount of seconds a user has to wait before sending another message (0-21600)
        rate_limit_per_user: ?isize = null,
        /// contents of the first message in the forum thread
        message: struct {
            /// Message contents (up to 2000 characters)
        content: ?[]const u8 = null,
            /// Embedded rich content (up to 6000 characters)
        embeds: ?[]Embed = null,
            /// Allowed mentions for the message
        allowed_mentions: ?[]AllowedMentions = null,
            /// Components to include with the message
        components: ?[][]MessageComponent = null,
            /// IDs of up to 3 stickers in the server to send in the message
        sticker_ids: ?[][]const u8 = null,
            /// JSON-encoded body of non-file params, only for multipart/form-data requests. See {@link https://discord.com/developers/docs/reference#uploading-files Uploading Files};
        payload_json: ?[]const u8 = null,
            /// Attachment objects with filename and description. See {@link https://discord.com/developers/docs/reference#uploading-files Uploading Files};
        attachments: ?[]Attachment = null,
            /// Message flags combined as a bitfield, only SUPPRESS_EMBEDS can be set
        flags: ?MessageFlags = null,
        },
        /// the IDs of the set of tags that have been applied to a thread in a GUILD_FORUM channel
        applied_tags: ?[][]const u8 = null,
    };

    pub const ArchivedThreads = struct {
        threads: []Channel,
        members: []ThreadMember,
        hasMore: bool,
    };

    pub const ActiveThreads = struct {
        threads: []Channel,
        members: []ThreadMember,
    };

    pub const VanityUrl = struct {
        code: ?[]const u8 = null,
        uses: isize,
    };

    pub const PrunedCount = struct {
        pruned: isize,
    };

    /// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-guild-onboarding-structure
    pub const GuildOnboarding = struct {
        /// ID of the guild this onboarding is part of
        guild_id: Snowflake,
        /// Prompts shown during onboarding and in customize community
        prompts: []GuildOnboardingPrompt,
        /// Channel IDs that members get opted into automatically
        default_channel_ids: [][]const u8,
        /// Whether onboarding is enabled in the guild
        enabled: bool,
        /// Current mode of onboarding
        mode: GuildOnboardingMode,
    };

    /// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-onboarding-prompt-structure
    pub const GuildOnboardingPrompt = struct {
        /// ID of the prompt
        id: Snowflake,
        /// Type of prompt
        type: GuildOnboardingPromptType,
        /// Options available within the prompt
        options: []GuildOnboardingPromptOption,
        /// Title of the prompt
        title: []const u8,
        /// Indicates whether users are limited to selecting one option for the prompt
        single_select: bool,
        /// Indicates whether the prompt is required before a user completes the onboarding flow
        required: bool,
        /// Indicates whether the prompt is present in the onboarding flow. If `false`, the prompt will only appear in the Channels & Roles tab
        in_onboarding: bool,
    };

    /// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-prompt-option-structure
    pub const GuildOnboardingPromptOption = struct {
        /// ID of the prompt option
        id: Snowflake,
        /// IDs for channels a member is added to when the option is selected
        channel_ids: [][]const u8,
        /// IDs for roles assigned to a member when the option is selected
        role_ids: [][]const u8,
        ///
        /// Emoji of the option
        ///
        /// @remarks
        /// When creating or updating a prompt option, the `emoji_id`, `emoji_name`, and `emoji_animated` fields must be used instead of the emoji object.
        ///
        emoji: ?Emoji = null,
        ///
        /// Emoji ID of the option
        ///
        /// @remarks
        /// When creating or updating a prompt option, the `emoji_id`, `emoji_name`, and `emoji_animated` fields must be used instead of the emoji object.
        ///
        emoji_id: ?Snowflake = null,
        ///
        /// Emoji name of the option
        ///
        /// @remarks
        /// When creating or updating a prompt option, the `emoji_id`, `emoji_name`, and `emoji_animated` fields must be used instead of the emoji object.
        ///
        emoji_name: ?[]const u8 = null,
        ///
        /// Whether the emoji is animated
        ///
        /// @remarks
        /// When creating or updating a prompt option, the `emoji_id`, `emoji_name`, and `emoji_animated` fields must be used instead of the emoji object.
        ///
        emoji_animated: ?bool = null,
        /// Title of the option
        title: []const u8,
        /// Description of the option
        description: ?[]const u8 = null,
};

/// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-prompt-types
pub const GuildOnboardingPromptType = enum {
    MultipleChoice,
    DropDown,
};

/// https://discord.com/developers/docs/resources/guild#guild-onboarding-object-onboarding-mode
pub const GuildOnboardingMode = enum {
    /// Counts only Default Channels towards constraints
    OnboardingDefault,
    /// Counts Default Channels and Questions towards constraints
    OnboardingAdvanced,
};

/// https://discord.com/developers/docs/topics/teams#team-member-roles-team-member-role-types
pub const TeamMemberRole = enum {
    /// Owners are the most permissiable role, and can take destructive, irreversible actions like deleting the team itself. Teams are limited to 1 owner.
    owner,
    /// Admins have similar access as owners, except they cannot take destructive actions on the team or team-owned apps.
    admin,
    /// broken
    ///
    developer,
    /// Read-only members can access information about a team and any team-owned apps. Some examples include getting the IDs of applications and exporting payout records.
    read_only,
};

/// https://discord.com/developers/docs/resources/guild#bulk-guild-ban
pub const BulkBan = struct {
    /// list of user ids, that were successfully banned
    banned_users: [][]const u8,
    /// list of user ids, that were not banned
    failed_users: [][]const u8,
};
