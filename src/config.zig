// custom file for configurations you might want

const PremiumTypes = @import("./structures/shared.zig").PremiumTypes;
const Snowflake = @import("./structures/snowflake.zig").Snowflake;
const AvatarDecorationData = @import("./structures/user.zig").AvatarDecorationData;

/// https://discord.com/developers/docs/resources/user#user-object
/// modify this to your liking
pub const StoredUser = struct {
    username: []const u8,
    global_name: ?[]const u8 = null,
    locale: ?[]const u8 = null,
    flags: ?isize = null,
    premium_type: ?PremiumTypes = null,
    public_flags: ?isize = null,
    accent_color: ?isize = null,
    id: Snowflake,
    discriminator: []const u8,
    avatar: ?[]const u8 = null,
    bot: ?bool = null,
    system: ?bool = null,
    mfa_enabled: ?bool = null,
    verified: ?bool = null,
    email: ?[]const u8 = null,
    banner: ?[]const u8 = null,
    avatar_decoration_data: ?AvatarDecorationData = null,
    clan: ?[]const u8 = null,
};

const VerificationLevels = @import("./structures/shared.zig").VerificationLevels;
const DefaultMessageNotificationLevels = @import("./structures/shared.zig").DefaultMessageNotificationLevels;
const ExplicitContentFilterLevels = @import("./structures/shared.zig").ExplicitContentFilterLevels;
const GuildFeatures = @import("./structures/shared.zig").GuildFeatures;
const MfaLevels = @import("./structures/shared.zig").MfaLevels;
const SystemChannelFlags = @import("./structures/shared.zig").SystemChannelFlags;
const PremiumTiers = @import("./structures/shared.zig").PremiumTiers;
const GuildNsfwLevel = @import("./structures/shared.zig").GuildNsfwLevel;
const StageInstance = @import("./structures/channel.zig").StageInstance;
const WelcomeScreen = @import("./structures/channel.zig").WelcomeScreen;

/// https://discord.com/developers/docs/resources/guild#guild-object
/// modify this to your liking
pub const StoredGuild = struct {
    name: []const u8,
    widget_enabled: ?bool = null,
    verification_level: VerificationLevels,
    default_message_notifications: DefaultMessageNotificationLevels,
    explicit_content_filter: ExplicitContentFilterLevels,
    features: []GuildFeatures,
    mfa_level: MfaLevels,
    system_channel_flags: SystemChannelFlags,
    large: ?bool = null,
    unavailable: ?bool = null,
    member_count: ?isize = null,
    max_presences: ?isize = null,
    max_members: ?isize = null,
    vanity_url_code: ?[]const u8 = null,
    description: ?[]const u8 = null,
    premium_tier: PremiumTiers,
    premium_subscription_count: ?isize = null,
    /// returned from the GET /guilds/id endpoint when with_counts is true
    approximate_member_count: ?isize = null,
    /// returned from the GET /guilds/id endpoint when with_counts is true
    approximate_presence_count: ?isize = null,
    nsfw_level: GuildNsfwLevel,
    id: Snowflake,
    icon: ?[]const u8 = null,
    icon_hash: ?[]const u8 = null,
    splash: ?[]const u8 = null,
    discovery_splash: ?[]const u8 = null,
    owner_id: Snowflake,
    permissions: ?[]const u8 = null,
    afk_channel_id: ?Snowflake = null,
    widget_channel_id: ?Snowflake = null,
    application_id: ?Snowflake = null,
    system_channel_id: ?Snowflake = null,
    rules_channel_id: ?Snowflake = null,
    banner: ?[]const u8 = null,
    preferred_locale: []const u8,
    public_updates_channel_id: ?Snowflake = null,
    welcome_screen: ?WelcomeScreen = null,
    stage_instances: ?[]StageInstance = null,
    safety_alerts_channel_id: ?Snowflake = null,
};

const ChannelTypes = @import("./structures/shared.zig").ChannelTypes;
const Overwrite = @import("./structures/channel.zig").Overwrite;
const VideoQualityModes = @import("./structures/shared.zig").VideoQualityModes;
const ThreadMetadata = @import("./structures/thread.zig").ThreadMetadata;
const ChannelFlags = @import("./structures/shared.zig").ChannelFlags;
const ForumTag = @import("./structures/channel.zig").ForumTag;
const DefaultReactionEmoji = @import("./structures/channel.zig").DefaultReactionEmoji;
const SortOrderTypes = @import("./structures/shared.zig").SortOrderTypes;
const ForumLayout = @import("./structures/shared.zig").ForumLayout;

/// https://discord.com/developers/docs/resources/channel#channel-object
/// modify this to your liking
pub const StoredChannel = struct {
    id: Snowflake,
    type: ChannelTypes,
    guild_id: ?Snowflake = null,
    position: ?isize = null,
    permission_overwrites: ?[]Overwrite = null,
    name: ?[]const u8 = null,
    topic: ?[]const u8 = null,
    nsfw: ?bool = null,
    user_limit: ?isize = null,
    icon: ?[]const u8 = null,
    owner_id: ?Snowflake = null,
    application_id: ?Snowflake = null,
    managed: ?bool = null,
    parent_id: ?Snowflake = null,
    last_pin_timestamp: ?[]const u8 = null,
    rtc_region: ?[]const u8 = null,
    video_quality_mode: ?VideoQualityModes = null,
    message_count: ?isize = null,
    member_count: ?isize = null,
    /// Thread-specific fields not needed by other channels
    /// TODO: optimise this
    thread_metadata: ?ThreadMetadata = null,
    /// threads
    default_auto_archive_duration: ?isize = null,
    permissions: ?[]const u8 = null,
    flags: ?ChannelFlags = null,
    total_message_sent: ?isize = null,
    /// forum channels
    available_tags: ?[]ForumTag = null,
    /// forum channels
    applied_tags: ?[][]const u8 = null,
    /// forum channels
    default_reaction_emoji: ?DefaultReactionEmoji = null,
    /// threads and channels
    default_thread_rate_limit_per_user: ?isize = null,
    /// forum channels
    default_sort_order: ?SortOrderTypes = null,
    /// forum channels
    default_forum_layout: ?ForumLayout = null,
    /// When a thread is created this will be true on that channel payload for the thread.
    /// TODO: optimise this
    newly_created: ?bool = null,
};


/// https://discord.com/developers/docs/resources/emoji#emoji-object-emoji-structure
/// modifyus to your liking
pub const StoredEmoji = struct {
    name: ?[]const u8 = null,
    id: ?Snowflake = null,
    roles: ?[][]const u8 = null,
    user_id: ?Snowflake = null,
    require_colons: ?bool = null,
    managed: ?bool = null,
    animated: ?bool = null,
    available: ?bool = null,
};

const MessageTypes = @import("./structures/shared.zig").MessageTypes;
const Attachment = @import("./structures/attachment.zig").Attachment;
const Embed = @import("./structures/embed.zig").Embed;
const ChannelMention = @import("./structures/message.zig").ChannelMention;
const MessageActivity = @import("./structures/message.zig").MessageActivity;
const MessageFlags = @import("./structures/shared.zig").MessageFlags;
const StickerItem = @import("./structures/sticker.zig").StickerItem;
const Poll = @import("./structures/poll.zig").Poll;
const MessageCall = @import("./structures/message.zig").MessageCall;

/// https://discord.com/developers/docs/resources/channel#message-object
/// modify this to your liking
pub const StoredMessage = struct {
    id: Snowflake,
    channel_id: Snowflake,
    guild_id: ?Snowflake = null,
    author_id: Snowflake,
    member_id: ?Snowflake = null,
    content: ?[]const u8 = null,
    timestamp: []const u8,
    edited_timestamp: ?[]const u8 = null,
    tts: bool,
    mention_everyone: bool,
    mentions: []Snowflake,
    mention_roles: ?[][]const u8 = null,
    mention_channels: ?[]ChannelMention = null,
    attachments: []Attachment,
    embeds: []Embed,
    reactions: ?[]Snowflake = null,
    // Used for validating a message was sent
    //    nonce: ?union(enum) {int: isize,string: []const u8,} = null,
    pinned: bool,
    webhook_id: ?Snowflake = null,
    type: MessageTypes,
    // interactions or webhooks
    application_id: ?Snowflake = null,
    // Data showing the source of a crosspost, channel follow add, pin, or reply message
    //    message_reference: ?Omit(MessageReference, .{"failIfNotExists"}) = null,
    flags: ?MessageFlags = null,
    referenced_message_id: ?Snowflake = null,
    // The thread that was started from this message, includes thread member object
    //    thread: ?Omit(Channel, .{"member"}), //& { member: ThreadMember }; = null,
    components: ?[]Snowflake = null,
    sticker_items: ?[]StickerItem = null,
    /// threads, may be deleted?
    position: ?isize = null,
    poll: ?Poll = null,
    call: ?MessageCall = null,
};

const RoleFlags = @import("./structures/shared.zig").RoleFlags;
const RoleTags = @import("./structures/role.zig").RoleTags;

/// https://discord.com/developers/docs/topics/permissions#role-object-role-structure
/// modify this to your liking
pub const StoredRole = struct {
    id: Snowflake,
    hoist: bool,
    permissions: []const u8,
    managed: bool,
    mentionable: bool,
    tags: ?RoleTags = null,
    icon: ?[]const u8 = null,
    name: []const u8,
    color: isize,
    position: isize,
    unicode_emoji: ?[]const u8 = null,
    flags: RoleFlags,
};

const StickerTypes = @import("./structures/shared.zig").StickerTypes;
const StickerFormatTypes = @import("./structures/shared.zig").StickerFormatTypes;

/// https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-structure
/// I don't know why you'd cache a sticker, but I deliver what I promise
pub const StoredSticker = struct {
    id: Snowflake,
    pack_id: ?Snowflake = null,
    name: []const u8,
    description: []const u8,
    tags: []const u8,
    type: StickerTypes,
    format_type: StickerFormatTypes,
    available: ?bool = null,
    guild_id: ?Snowflake = null,
    user_id: ?Snowflake = null,
    sort_value: ?isize = null,
};

const ReactionCountDetails = @import("./structures/message.zig").ReactionCountDetails;

/// https://discord.com/developers/docs/resources/channel#reaction-object
/// This is actually beneficial to cache
pub const StoredReaction = struct {
    count: isize,
    count_details: ReactionCountDetails,
    me: bool,
    me_burst: bool,
    emoji_id: []const u8,
    burst_colors: [][]const u8,
};


/// https://discord.com/developers/docs/resources/guild#guild-member-object
/// modify this to your liking
pub const StoredMember = struct {
    pending: ?bool = null,
    user_id: ?Snowflake = null,
    nick: ?[]const u8 = null,
    avatar: ?[]const u8 = null,
    roles: [][]const u8,
    joined_at: []const u8,
    premium_since: ?[]const u8 = null,
    permissions: ?[]const u8 = null,
    flags: isize,
    avatar_decoration_data: ?AvatarDecorationData = null,
};

