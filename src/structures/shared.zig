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

const std = @import("std");
const Snowflake = @import("snowflake.zig").Snowflake;

pub const PresenceStatus = enum {
    online,
    dnd,
    idle,
    offline,
};

/// https://discord.com/developers/docs/resources/user#user-object-premium-types
pub const PremiumTypes = enum {
    None,
    NitroClassic,
    Nitro,
    NitroBasic,
};

/// https://discord.com/developers/docs/resources/user#user-object-user-flags
pub const UserFlags = packed struct {
    pub fn toRaw(self: UserFlags) u34 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u34) UserFlags {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    DiscordEmployee: bool = false,
    PartneredServerOwner: bool = false,
    HypeSquadEventsMember: bool = false,
    BugHunterLevel1: bool = false,
    MfaSms: bool = false,
    PremiumPromoDismissed: bool = false,
    HouseBravery: bool = false,
    HouseBrilliance: bool = false,
    HouseBalance: bool = false,
    EarlySupporter: bool = false,
    TeamUser: bool = false,
    PartnerOrVerificationApplication: bool = false,
    System: bool = false,
    HasUnreadUrgentMessages: bool = false,
    BugHunterLevel2: bool = false,
    UnderageDeleted: bool = false,
    VerifiedBot: bool = false,
    EarlyVerifiedBotDeveloper: bool = false,
    DiscordCertifiedModerator: bool = false,
    BotHttpInteractions: bool = false,
    Spammer: bool = false,
    DisablePremium: bool = false,
    ActiveDeveloper: bool = false,
    _pad: u10 = 0,
    Quarantined: bool = false,
};

pub const PremiumUsageFlags = packed struct {
    pub fn toRaw(self: PremiumUsageFlags) u8 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u8) PremiumUsageFlags {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    PremiumDiscriminator: bool = false,
    AnimatedAvatar: bool = false,
    ProfileBanner: bool = false,
    _pad: u5 = 0,
};

pub const PurchasedFlags = packed struct {
    pub fn toRaw(self: PurchasedFlags) u8 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u8) PurchasedFlags {
        return @bitCast(raw);
    }

    NitroClassic: bool = false,
    Nitro: bool = false,
    GuildBoost: bool = false,
    NitroBasic: bool = false,
    _pad: u4 = 0,
};

pub const MemberFlags = packed struct {
    pub fn toRaw(self: MemberFlags) u16 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u16) MemberFlags {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }
    ///
    /// Member has left and rejoined the guild
    ///
    /// @remarks
    /// This value is not editable
    ////Message
    DidRejoin: bool = false,
    ///
    /// Member has completed onboarding
    ///
    /// @remarks
    /// This value is not editable
    ////
    CompletedOnboarding: bool = false,
    /// Member is exempt from guild verification requirements
    BypassesVerification: bool = false,
    ///
    /// Member has started onboarding
    ///
    /// @remarks
    /// This value is not editable
    ////
    StartedOnboarding: bool = false,
    ///
    /// Member is a guest and can only access the voice channel they were invited to
    ///
    /// @remarks
    /// This value is not editable
    ////
    IsGuest: bool = false,
    ///
    /// Member has started Server Guide new member actions
    ///
    /// @remarks
    /// This value is not editable
    ////
    StartedHomeActions: bool = false,
    ///
    /// Member has completed Server Guide new member actions
    ///
    /// @remarks
    /// This value is not editable
    ////
    CompletedHomeActions: bool = false,
    ///
    /// Member's username, display name, or nickname is blocked by AutoMod
    ///
    /// @remarks
    /// This value is not editable
    ////
    AutomodQuarantinedUsername: bool = false,
    _pad: u1 = 0,
    ///
    /// Member has dismissed the DM settings upsell
    ///
    /// @remarks
    /// This value is not editable
    ////
    DmSettingsUpsellAcknowledged: bool = false,
    _pad2: u6 = 0,
};

/// https://discord.com/developers/docs/resources/channel#channels-resource
pub const ChannelFlags = packed struct {
    pub fn toRaw(self: ChannelFlags) u32 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u32) ChannelFlags {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    None: bool = false,
    /// this thread is pinned to the top of its parent `GUILD_FORUM` channel
    Pinned: bool = false,
    _pad: u3 = 0,
    /// Whether a tag is required to be specified when creating a thread in a `GUILD_FORUM` or a GUILD_MEDIA channel. Tags are specified in the `applied_tags` field.
    RequireTag: bool = false,
    _pad1: u11 = 0,
    /// When set hides the embedded media download options. Available only for media channels.
    HideMediaDownloadOptions: bool = false,
    _pad2: u14,
};

/// https://discord.com/developers/docs/topics/permissions#role-object-role-flags
pub const RoleFlags = packed struct {
    pub fn toRaw(self: RoleFlags) u2 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u2) RoleFlags {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    None: bool = false,
    /// Role can be selected by members in an onboarding prompt
    InPrompt: bool = false,
};

pub const AttachmentFlags = packed struct {
    pub fn toRaw(self: AttachmentFlags) u8 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u8) AttachmentFlags {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    None: bool = false,
    _pad: u1 = 0,
    /// This attachment has been edited using the remix feature on mobile
    IsRemix: bool = false,
    _pad1: u5 = 0,
};

/// https://discord.com/developers/docs/monetization/skus#sku-object-sku-flags
pub const SkuFlags = packed struct {
    pub fn toRaw(self: SkuFlags) u16 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u16) SkuFlags {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    _pad: u2 = 0,
    /// SKU is available for purchase
    Available: bool = false,
    _pad1: u5 = 0,
    /// Recurring SKU that can be purchased by a user and applied to a single server. Grants access to every user in that server.
    GuildSubscription: bool = false,
    /// Recurring SKU purchased by a user for themselves. Grants access to the purchasing user in every server.
    UserSubscription: bool = false,
    _pad2: u6,
};

/// https://discord.com/developers/docs/resources/channel#message-object-message-flags
pub const MessageFlags = packed struct {
    pub fn toRaw(self: MessageFlags) u16 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u16) MessageFlags {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    /// This message has been published to subscribed channels (via Channel Following)
    Crossposted: bool = false,
    /// This message originated from a message in another channel (via Channel Following)
    IsCrosspost: bool = false,
    /// Do not include any embeds when serializing this message
    SuppressEmbeds: bool = false,
    /// The source message for this crosspost has been deleted (via Channel Following)
    SourceMessageDeleted: bool = false,
    /// This message came from the urgent message system
    Urgent: bool = false,
    /// This message has an associated thread, with the same id as the message
    HasThread: bool = false,
    /// This message is only visible to the user who invoked the Interaction
    Ephemeral: bool = false,
    /// This message is an Interaction Response and the bot is "thinking"
    Loading: bool = false,
    /// This message failed to mention some roles and add their members to the thread
    FailedToMentionSomeRolesInThread: bool = false,
    _pad: u4 = 0,
    /// This message will not trigger push and desktop notifications
    SuppressNotifications: bool = false,
    /// This message is a voice message
    IsVoiceMessage: bool = false,
    _pad1: u1 = 0,
};

/// https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-flags
pub const ActivityFlags = packed struct {
    pub fn toRaw(self: MessageFlags) u16 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u16) MessageFlags {
        return @bitCast(raw);
    }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    Instance: bool = false,
    Join: bool = false,
    Spectate: bool = false,
    JoinRequest: bool = false,
    Sync: bool = false,
    Play: bool = false,
    PartyPrivacyFriends: bool = false,
    PartyPrivacyVoiceChannel: bool = false,
    Embedded: bool = false,
    _pad: u7 = 0,
};

/// https://discord.com/developers/docs/resources/guild#integration-object-integration-expire-behaviors
pub const IntegrationExpireBehaviors = enum {
    RemoveRole,
    Kick,
};

/// https://discord.com/developers/docs/topics/teams#data-models-membership-state-enum
pub const TeamMembershipStates = enum(u4) {
    Invited = 1,
    Accepted = 2,
};

/// https://discord.com/developers/docs/topics/oauth2#application-application-flags
pub const ApplicationFlags = packed struct {
    pub fn toRaw(self: ApplicationFlags) u32 {
        return @bitCast(self);
    }

    pub fn fromRaw(raw: u32) ApplicationFlags {
        return @bitCast(raw);
    }

    // this should be the default behavior
    // but unfortunately the zig std devs have nothing in their heads
    // so we have to do this manually for each struct, what a fucking nightmare
    // I have no clue what to do for bigger ints, I'll figure it out
    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }

    _pad: u5 = 0,
    /// Indicates if an app uses the Auto Moderation API.
    ApplicationAutoModerationRuleCreateBadge: bool = false,
    _pad1: u6 = 0,
    /// Intent required for bots in **100 or more servers*  /// to receive 'presence_update' events
    GatewayPresence: bool = false,
    /// Intent required for bots in under 100 servers to receive 'presence_update' events
    GatewayPresenceLimited: bool = false,
    /// Intent required for bots in **100 or more servers*  /// to receive member-related events like 'guild_member_add'.
    GatewayGuildMembers: bool = false,
    /// Intent required for bots in under 100 servers to receive member-related events like 'guild_member_add'.
    GatewayGuildMembersLimited: bool = false,
    /// Indicates unusual growth of an app that prevents verification
    VerificationPendingGuildLimit: bool = false,
    /// Indicates if an app is embedded within the Discord client (currently unavailable publicly)
    Embedded: bool = false,
    /// Intent required for bots in **100 or more servers*  /// to receive [message content](https://support-dev.discord.com/hc/en-us/articles/4404772028055)
    GatewayMessageContent: bool = false,
    /// Intent required for bots in under 100 servers to receive [message content](https://support-dev.discord.com/hc/en-us/articles/4404772028055), found in Bot Settings
    GatewayMessageContentLimited: bool = false,
    _pad2: u4 = 0,
    /// Indicates if an app has registered global application commands
    ApplicationCommandBadge: bool = false,
    _pad3: u7,
};

/// https://discord.com/developers/docs/interactions/message-components#component-types
pub const MessageComponentTypes = enum(u4) {
    /// A container for other components
    ActionRow = 1,
    /// A button object
    Button,
    /// A select menu for picking from choices
    SelectMenu,
    /// A text input object
    InputText,
    /// Select menu for users
    SelectMenuUsers,
    /// Select menu for roles
    SelectMenuRoles,
    /// Select menu for users and roles
    SelectMenuUsersAndRoles,
    /// Select menu for channels
    SelectMenuChannels,
};

pub const TextStyles = enum(u4) {
    /// Intended for short single-line text
    Short = 1,
    /// Intended for much longer inputs
    Paragraph = 2,
};

/// https://discord.com/developers/docs/interactions/message-components#buttons-button-styles
pub const ButtonStyles = enum(u4) {
    /// A blurple button
    Primary = 1,
    /// A grey button
    Secondary,
    /// A green button
    Success,
    /// A red button
    Danger,
    /// A button that navigates to a URL
    Link,
    /// A blurple button to show a Premium item in the shop
    Premium,
};

/// https://discord.com/developers/docs/resources/channel#allowed-mentions-object-allowed-mention-types
pub const AllowedMentionsTypes = enum {
    /// Controls role mentions
    roles,
    /// Controls user mentions
    users,
    /// Controls \@everyone and \@here mentions
    everyone,
};

/// https://discord.com/developers/docs/resources/webhook#webhook-object-webhook-types
pub const WebhookTypes = enum(u4) {
    /// Incoming Webhooks can post messages to channels with a generated token
    Incoming = 1,
    /// Channel Follower Webhooks are internal webhooks used with Channel Following to post new messages into channels
    ChannelFollower,
    /// Application webhooks are webhooks used with Interactions
    Application,
};

/// https://discord.com/developers/docs/resources/channel#embed-object-embed-types
/// perhaps union?
pub const EmbedTypes = enum {
    rich,
    image,
    video,
    gifv,
    article,
    link,
    poll_res,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-default-message-notification-level
pub const DefaultMessageNotificationLevels = enum {
    /// Members will receive notifications for all messages by default
    AllMessages,
    /// Members will receive notifications only for messages that \@mention them by default
    OnlyMentions,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-explicit-content-filter-level
pub const ExplicitContentFilterLevels = enum {
    /// Media content will not be scanned
    Disabled,
    /// Media content sent by members without roles will be scanned
    MembersWithoutRoles,
    /// Media content sent by all members will be scanned
    AllMembers,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-verification-level
pub const VerificationLevels = enum {
    /// Unrestricted
    None,
    /// Must have verified email on account
    Low,
    /// Must be registered on Discord for longer than 5 minutes
    Medium,
    /// Must be a member of the server for longer than 10 minutes
    High,
    /// Must have a verified phone number
    VeryHigh,
};

/// https://discord.com/developers/docs/resources/guild#guild-object-guild-features
pub const GuildFeatures = enum {
    /// Guild has access to set an invite splash background
    INVITE_SPLASH,
    /// Guild has access to set a vanity URL
    VANITY_URL,
    /// Guild is verified
    VERIFIED,
    /// Guild is partnered
    PARTNERED,
    /// Guild can enable welcome screen, Membership Screening, stage channels and discovery, and receives community updates
    COMMUNITY,
    /// Guild has enabled monetization.
    CREATOR_MONETIZABLE_PROVISIONAL,
    /// Guild has enabled the role subscription promo page.
    CREATOR_STORE_PAGE,
    /// Guild has been set as a support server on the App Directory
    DEVELOPER_SUPPORT_SERVER,
    /// Guild has access to create news channels
    NEWS,
    /// Guild is able to be discovered in the directory
    DISCOVERABLE,
    /// Guild is able to be featured in the directory
    FEATURABLE,
    /// Guild has access to set an animated guild icon
    ANIMATED_ICON,
        /// Guild has access to set a guild banner image
        BANNER,
        /// Guild has enabled the welcome screen
        WELCOME_SCREEN_ENABLED,
        /// Guild has enabled [Membership Screening](https://discord.com/developers/docs/resources/guild#membership-screening-object)
        MEMBER_VERIFICATION_GATE_ENABLED,
        /// Guild can be previewed before joining via Membership Screening or the directory
        PREVIEW_ENABLED,
        /// Guild has enabled ticketed events
        TICKETED_EVENTS_ENABLED,
        /// Guild has increased custom sticker slots
        MORE_STICKERS,
        /// Guild is able to set role icons
        ROLE_ICONS,
        /// Guild has role subscriptions that can be purchased.
        ROLE_SUBSCRIPTIONS_AVAILABLE_FOR_PURCHASE,
        /// Guild has enabled role subscriptions.
        ROLE_SUBSCRIPTIONS_ENABLED,
        /// Guild has set up auto moderation rules
        AUTO_MODERATION,
        /// Guild has paused invites, preventing new users from joining
        INVITES_DISABLED,
        /// Guild has access to set an animated guild banner image
        ANIMATED_BANNER,
        /// Guild has disabled alerts for join raids in the configured safety alerts channel
        RAID_ALERTS_DISABLED,
        /// Guild is using the old permissions configuration behavior
        APPLICATION_COMMAND_PERMISSIONS_V2,
    };

    /// https://discord.com/developers/docs/resources/guild#guild-object-mfa-level
    pub const MfaLevels = enum {
        /// Guild has no MFA/2FA requirement for moderation actions
        None,
        /// Guild has a 2FA requirement for moderation actions
        Elevated,
    };

    /// https://discord.com/developers/docs/resources/guild#guild-object-system-channel-flags
    pub const SystemChannelFlags = packed struct {
        pub fn toRaw(self: SystemChannelFlags) u8 {
            return @bitCast(self);
        }

        pub fn fromRaw(raw: u8) SystemChannelFlags {
            return @bitCast(raw);
        }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }


        /// Suppress member join notifications
        SuppressJoinNotifications: bool = false,
        /// Suppress server boost notifications
        SuppressPremiumSubscriptions: bool = false,
        /// Suppress server setup tips
        SuppressGuildReminderNotifications: bool = false,
        /// Hide member join sticker reply buttons
        SuppressJoinNotificationReplies: bool = false,
        _pad: u4 = 0,
    };

    /// https://discord.com/developers/docs/resources/guild#guild-object-premium-tier
    pub const PremiumTiers = enum {
        /// Guild has not unlocked any Server Boost perks
        None,
        /// Guild has unlocked Server Boost level 1 perks
        Tier1,
        /// Guild has unlocked Server Boost level 2 perks
        Tier2,
        /// Guild has unlocked Server Boost level 3 perks
        Tier3,
    };

    /// https://discord.com/developers/docs/resources/guild#guild-object-guild-nsfw-level
    pub const GuildNsfwLevel = enum {
        Default,
        Explicit,
        Safe,
        AgeRestricted,
    };

    /// https://discord.com/developers/docs/resources/channel#channel-object-channel-types
    pub const ChannelTypes = packed struct {
        pub fn toRaw(self: ChannelTypes) u32 {
            return @bitCast(self);
        }

        pub fn fromRaw(raw: u32) ChannelTypes {
            return @bitCast(raw);
        }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }


        /// A text channel within a server
        GuildText: bool = false,
        /// A direct message between users
        DM: bool = false,
        /// A voice channel within a server
        GuildVoice: bool = false,
        /// A direct message between multiple users
        GroupDm: bool = false,
        /// An organizational category that contains up to 50 channels
        GuildCategory: bool = false,
        /// A channel that users can follow and crosspost into their own server
        GuildAnnouncement: bool = false,
        _pad: u4 = 0,
        /// A temporary sub-channel within a GUILD_ANNOUNCEMENT channel
        AnnouncementThread: bool = false,
        /// A temporary sub-channel within a GUILD_TEXT or GUILD_FORUM channel
        PublicThread: bool = false,
        /// A temporary sub-channel within a GUILD_TEXT channel that is only viewable by those invited and those with the MANAGE_THREADS permission
        PrivateThread: bool = false,
        /// A voice channel for hosting events with an audience
        GuildStageVoice: bool = false,
        /// A channel in a hub containing the listed servers
        GuildDirectory: bool = false,
        /// A channel which can only contains threads
        GuildForum: bool = false,
        /// Channel that can only contain threads, similar to GUILD_FORUM channels
        GuildMedia: bool = false,
        _pad1: u15 = 0,
    };

    pub const OverwriteTypes = enum {
        Role,
        Member,
    };

    pub const VideoQualityModes = enum(u4) {
        /// Discord chooses the quality for optimal performance
        Auto = 1,
        /// 720p
        Full,
    };

    /// https://discord.com/developers/docs/topics/gateway-events#activity-object-activity-types
    pub const ActivityTypes = enum(u4) {
        Playing = 0,
        Streaming = 1,
        Listening = 2,
        Watching = 3,
        Custom = 4,
        Competing = 5,
    };

    /// https://discord.com/developers/docs/resources/channel#message-object-message-types
    pub const MessageTypes = enum(u8) {
        Default,
        RecipientAdd,
        RecipientRemove,
        Call,
        ChannelNameChange,
        ChannelIconChange,
        ChannelPinnedMessage,
        UserJoin,
        GuildBoost,
        GuildBoostTier1,
        GuildBoostTier2,
        GuildBoostTier3,
        ChannelFollowAdd,
        GuildDiscoveryDisqualified = 14,
        GuildDiscoveryRequalified,
        GuildDiscoveryGracePeriodInitialWarning,
        GuildDiscoveryGracePeriodFinalWarning,
        ThreadCreated,
        Reply,
        ChatInputCommand,
        ThreadStarterMessage,
        GuildInviteReminder,
        ContextMenuCommand,
        AutoModerationAction,
        RoleSubscriptionPurchase,
        InteractionPremiumUpsell,
        StageStart,
        StageEnd,
        StageSpeaker,
        StageTopic = 31,
        GuildApplicationPremiumSubscription,
        GuildIncidentAlertModeEnabled = 36,
        GuildIncidentAlertModeDisabled,
        GuildIncidentReportRaid,
        GuildIncidentReportFalseAlarm,
        PurchaseNotification = 44,
        PollResult = 46,
    };

    /// https://discord.com/developers/docs/resources/channel#message-object-message-activity-types
    pub const MessageActivityTypes = enum(u4) {
        Join = 1,
        Spectate = 2,
        Listen = 3,
        JoinRequest = 5,
    };

    /// https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-types
    pub const StickerTypes = enum(u4) {
        /// an official sticker in a pack
        Standard = 1,
        /// a sticker uploaded to a guild for the guild's members
        Guild = 2,
    };

    /// https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-format-types
    pub const StickerFormatTypes = enum(u4) {
        Png = 1,
        APng,
        Lottie,
        Gif,
    };

    /// https://discord.com/developers/docs/interactions/slash-commands#interaction-interactiontype
    pub const InteractionTypes = enum(u4) {
        Ping = 1,
        ApplicationCommand = 2,
        MessageComponent = 3,
        ApplicationCommandAutocomplete = 4,
        ModalSubmit = 5,
    };

    /// https://discord.com/developers/docs/interactions/slash-commands#applicationcommandoptiontype
    pub const ApplicationCommandOptionTypes = enum(u4) {
        SubCommand = 1,
        SubCommandGroup,
        String,
        Integer,
        Boolean,
        User,
        Channel,
        Role,
        Mentionable,
        Number,
        Attachment,
    };

    /// https://discord.com/developers/docs/resources/audit-log#audit-log-entry-object-audit-log-events
    pub const AuditLogEvents = enum(u4) {
        /// Server settings were updated
        GuildUpdate = 1,
        /// Channel was created
        ChannelCreate = 10,
        /// Channel settings were updated
        ChannelUpdate,
        /// Channel was deleted
        ChannelDelete,
        /// Permission overwrite was added to a channel
        ChannelOverwriteCreate,
        /// Permission overwrite was updated for a channel
        ChannelOverwriteUpdate,
        /// Permission overwrite was deleted from a channel
        ChannelOverwriteDelete,
        /// Member was removed from server
        MemberKick = 20,
        /// Members were pruned from server
        MemberPrune,
        /// Member was banned from server
        MemberBanAdd,
        /// Server ban was lifted for a member
        MemberBanRemove,
        /// Member was updated in server
        MemberUpdate,
        /// Member was added or removed from a role
        MemberRoleUpdate,
        /// Member was moved to a different voice channel
        MemberMove,
        /// Member was disconnected from a voice channel
        MemberDisconnect,
        /// Bot user was added to server
        BotAdd,
        /// Role was created
        RoleCreate = 30,
        /// Role was edited
        RoleUpdate,
        /// Role was deleted
        RoleDelete,
        /// Server invite was created
        InviteCreate = 40,
        /// Server invite was updated
        InviteUpdate,
        /// Server invite was deleted
        InviteDelete,
        /// Webhook was created
        WebhookCreate = 50,
        /// Webhook properties or channel were updated
        WebhookUpdate,
        /// Webhook was deleted
        WebhookDelete,
        /// Emoji was created
        EmojiCreate = 60,
        /// Emoji name was updated
        EmojiUpdate,
        /// Emoji was deleted
        EmojiDelete,
        /// Single message was deleted
        MessageDelete = 72,
        /// Multiple messages were deleted
        MessageBulkDelete,
        /// Messaged was pinned to a channel
        MessagePin,
        /// Message was unpinned from a channel
        MessageUnpin,
        /// App was added to server
        IntegrationCreate = 80,
        /// App was updated (as an example, its scopes were updated)
        IntegrationUpdate,
        /// App was removed from server
        IntegrationDelete,
        /// Stage instance was created (stage channel becomes live)
        StageInstanceCreate,
        /// Stage instace details were updated
        StageInstanceUpdate,
        /// Stage instance was deleted (stage channel no longer live)
        StageInstanceDelete,
        /// Sticker was created
        StickerCreate = 90,
        /// Sticker details were updated
        StickerUpdate,
        /// Sticker was deleted
        StickerDelete,
        /// Event was created
        GuildScheduledEventCreate = 100,
        /// Event was updated
        GuildScheduledEventUpdate,
        /// Event was cancelled
        GuildScheduledEventDelete,
        /// Thread was created in a channel
        ThreadCreate = 110,
        /// Thread was updated
        ThreadUpdate,
        /// Thread was deleted
        ThreadDelete,
        /// Permissions were updated for a command
        ApplicationCommandPermissionUpdate = 121,
        /// Auto moderation rule was created
        AutoModerationRuleCreate = 140,
        /// Auto moderation rule was updated
        AutoModerationRuleUpdate,
        /// Auto moderation rule was deleted
        AutoModerationRuleDelete,
        /// Message was blocked by AutoMod according to a rule.
        AutoModerationBlockMessage,
        /// Message was flagged by AutoMod
        AudoModerationFlagMessage,
        /// Member was timed out by AutoMod
        AutoModerationMemberTimedOut,
        /// Creator monetization request was created
        CreatorMonetizationRequestCreated = 150,
        /// Creator monetization terms were accepted
        CreatorMonetizationTermsAccepted,
        /// Guild Onboarding Question was created
        OnBoardingPromptCreate = 163,
        /// Guild Onboarding Question was updated
        OnBoardingPromptUpdate,
        /// Guild Onboarding Question was deleted
        OnBoardingPromptDelete,
        /// Guild Onboarding was created
        OnBoardingCreate,
        /// Guild Onboarding was updated
        OnBoardingUpdate,
        /// Guild Server Guide was created
        HomeSettingsCreate = 190,
        /// Guild Server Guide was updated
        HomeSettingsUpdate,
    };

    pub const ScheduledEventPrivacyLevel = enum(u4) {
        /// the scheduled event is only accessible to guild members
        GuildOnly = 2,
    };

    pub const ScheduledEventEntityType = enum(u4) {
        StageInstance = 1,
        Voice,
        External,
    };

    pub const ScheduledEventStatus = enum(u4) {
        Scheduled = 1,
        Active,
        Completed,
        Canceled,
    };

    /// https://discord.com/developers/docs/resources/invite#invite-object-target-user-types
    pub const TargetTypes = enum(u4) {
        Stream = 1,
        EmbeddedApplication,
    };

    pub const ApplicationCommandTypes = enum(u4) {
        /// A text-based command that shows up when a user types `/`
        ChatInput = 1,
        /// A UI-based command that shows up when you right click or tap on a user
        User,
        /// A UI-based command that shows up when you right click or tap on a message
        Message,
        /// A UI-based command that represents the primary way to invoke an app's Activity
        PrimaryEntryPoint,
    };

    pub const ApplicationCommandPermissionTypes = enum(u4) {
        Role = 1,
        User,
        Channel,
    };

    /// https://discord.com/developers/docs/topics/permissions#permissions-bitwise-permission-flags
    /// Permissions v2
    pub const BitwisePermissionFlags = packed struct {
        pub fn toRaw(self: BitwisePermissionFlags) u64 {
            return @bitCast(self);
        }

        pub fn fromRaw(raw: u64) BitwisePermissionFlags {
            return @bitCast(raw);
        }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
        if (src != .integer) @panic("Invalid value for bitfield");
        return fromRaw(@intCast(src.integer));
    }


        /// Allows creation of instant invites
        CREATE_INSTANT_INVITE: bool = false,
        /// Allows kicking members
        KICK_MEMBERS: bool = false,
        /// Allows banning members
        BAN_MEMBERS: bool = false,
        /// Allows all permissions and bypasses channel permission overwrites
        ADMINISTRATOR: bool = false,
        /// Allows management and editing of channels
        MANAGE_CHANNELS: bool = false,
        /// Allows management and editing of the guild
        MANAGE_GUILD: bool = false,
        /// Allows for the addition of reactions to messages
        ADD_REACTIONS: bool = false,
        /// Allows for viewing of audit logs
        VIEW_AUDIT_LOG: bool = false,
        /// Allows for using priority speaker in a voice channel
        PRIORITY_SPEAKER: bool = false,
        /// Allows the user to go live
        STREAM: bool = false,
        /// Allows guild members to view a channel, which includes reading messages in text channels and joining voice channels
        VIEW_CHANNEL: bool = false,
        /// Allows for sending messages in a channel. (does not allow sending messages in threads)
        SEND_MESSAGES: bool = false,
        /// Allows for sending of /tts messages
        SEND_TTS_MESSAGES: bool = false,
        /// Allows for deletion of other users messages
        MANAGE_MESSAGES: bool = false,
        /// Links sent by users with this permission will be auto-embedded
        EMBED_LINKS: bool = false,
        /// Allows for uploading images and files
        ATTACH_FILES: bool = false,
        /// Allows for reading of message history
        READ_MESSAGE_HISTORY: bool = false,
        /// Allows for using the \@everyone tag to notify all users in a channel, and the \@here tag to notify all online users in a channel
        MENTION_EVERYONE: bool = false,
        /// Allows the usage of custom emojis from other servers
        USE_EXTERNAL_EMOJIS: bool = false,
        /// Allows for viewing guild insights
        VIEW_GUILD_INSIGHTS: bool = false,
        /// Allows for joining of a voice channel
        CONNECT: bool = false,
        /// Allows for speaking in a voice channel
        SPEAK: bool = false,
        /// Allows for muting members in a voice channel
        MUTE_MEMBERS: bool = false,
        /// Allows for deafening of members in a voice channel
        DEAFEN_MEMBERS: bool = false,
        /// Allows for moving of members between voice channels
        MOVE_MEMBERS: bool = false,
        /// Allows for using voice-activity-detection in a voice channel
        USE_VAD: bool = false,
        /// Allows for modification of own nickname
        CHANGE_NICKNAME: bool = false,
        /// Allows for modification of other users nicknames
        MANAGE_NICKNAMES: bool = false,
        /// Allows management and editing of roles
        MANAGE_ROLES: bool = false,
        /// Allows management and editing of webhooks
        MANAGE_WEBHOOKS: bool = false,
        /// Allows for editing and deleting emojis, stickers, and soundboard sounds created by all users
        MANAGE_GUILD_EXPRESSIONS: bool = false,
        /// Allows members to use application commands in text channels
        USE_SLASH_COMMANDS: bool = false,
        /// Allows for requesting to speak in stage channels.
        REQUEST_TO_SPEAK: bool = false,
        /// Allows for editing and deleting scheduled events created by all users
        MANAGE_EVENTS: bool = false,
        /// Allows for deleting and archiving threads, and viewing all private threads
        MANAGE_THREADS: bool = false,
        /// Allows for creating public and announcement threads
        CREATE_PUBLIC_THREADS: bool = false,
        /// Allows for creating private threads
        CREATE_PRIVATE_THREADS: bool = false,
        /// Allows the usage of custom stickers from other servers
        USE_EXTERNAL_STICKERS: bool = false,
        /// Allows for sending messages in threads
        SEND_MESSAGES_IN_THREADS: bool = false,
        /// Allows for launching activities (applications with the `EMBEDDED` flag) in a voice channel.
        USE_EMBEDDED_ACTIVITIES: bool = false,
        /// Allows for timing out users to prevent them from sending or reacting to messages in chat and threads, and from speaking in voice and stage channels
        MODERATE_MEMBERS: bool = false,
        /// Allows for viewing role subscription insights.
        VIEW_CREATOR_MONETIZATION_ANALYTICS: bool = false,
        /// Allows for using soundboard in a voice channel.
        USE_SOUNDBOARD: bool = false,
        /// Allows for creating emojis, stickers, and soundboard sounds, and editing and deleting those created by the current user
        CREATE_GUILD_EXPRESSIONS: bool = false,
        /// Allows for creating scheduled events, and editing and deleting those created by the current user
        CREATE_EVENTS: bool = false,
        /// Allows the usage of custom soundboards sounds from other servers
        USE_EXTERNAL_SOUNDS: bool = false,
        /// Allows sending voice messages
        SEND_VOICE_MESSAGES: bool = false,
        /// Allows sending polls
        SEND_POLLS: bool = false,
        /// Allows user-installed apps to send public responses. When disabled, users will still be allowed to use their apps but the responses will be ephemeral. This only applies to apps not also installed to the server.
        USE_EXTERNAL_APPS: bool = false,
        _pad: u15 = 0,
    };

    pub const PermissionStrings = union(enum) {
        /// Allows creation of instant invites
        CREATE_INSTANT_INVITE,
        /// Allows kicking members
        KICK_MEMBERS,
        /// Allows banning members
        BAN_MEMBERS,
        /// Allows all permissions and bypasses channel permission overwrites
        ADMINISTRATOR,
        /// Allows management and editing of channels
        MANAGE_CHANNELS,
        /// Allows management and editing of the guild
        MANAGE_GUILD,
        /// Allows for the addition of reactions to messages
        ADD_REACTIONS,
        /// Allows for viewing of audit logs
        VIEW_AUDIT_LOG,
        /// Allows for using priority speaker in a voice channel
        PRIORITY_SPEAKER,
        /// Allows the user to go live
        STREAM,
        /// Allows guild members to view a channel, which includes reading messages in text channels and joining voice channels
        VIEW_CHANNEL,
        /// Allows for sending messages in a channel. (does not allow sending messages in threads)
        SEND_MESSAGES,
        /// Allows for sending of /tts messages
        SEND_TTS_MESSAGES,
        /// Allows for deletion of other users messages
        MANAGE_MESSAGES,
        /// Links sent by users with this permission will be auto-embedded
        EMBED_LINKS,
        /// Allows for uploading images and files
        ATTACH_FILES,
        /// Allows for reading of message history
        READ_MESSAGE_HISTORY,
        /// Allows for using the \@everyone tag to notify all users in a channel, and the \@here tag to notify all online users in a channel
        MENTION_EVERYONE,
        /// Allows the usage of custom emojis from other servers
        USE_EXTERNAL_EMOJIS,
        /// Allows for viewing guild insights
        VIEW_GUILD_INSIGHTS,
        /// Allows for joining of a voice channel
        CONNECT,
        /// Allows for speaking in a voice channel
        SPEAK,
        /// Allows for muting members in a voice channel
        MUTE_MEMBERS,
        /// Allows for deafening of members in a voice channel
        DEAFEN_MEMBERS,
        /// Allows for moving of members between voice channels
        MOVE_MEMBERS,
        /// Allows for using voice-activity-detection in a voice channel
        USE_VAD,
        /// Allows for modification of own nickname
        CHANGE_NICKNAME,
        /// Allows for modification of other users nicknames
        MANAGE_NICKNAMES,
        /// Allows management and editing of roles
        MANAGE_ROLES,
        /// Allows management and editing of webhooks
        MANAGE_WEBHOOKS,
        /// Allows for editing and deleting emojis, stickers, and soundboard sounds created by all users
        MANAGE_GUILD_EXPRESSIONS,
        /// Allows members to use application commands in text channels
        USE_SLASH_COMMANDS,
        /// Allows for requesting to speak in stage channels.
        REQUEST_TO_SPEAK,
        /// Allows for editing and deleting scheduled events created by all users
        MANAGE_EVENTS,
        /// Allows for deleting and archiving threads, and viewing all private threads
        MANAGE_THREADS,
        /// Allows for creating public and announcement threads
        CREATE_PUBLIC_THREADS,
        /// Allows for creating private threads
        CREATE_PRIVATE_THREADS,
        /// Allows the usage of custom stickers from other servers
        USE_EXTERNAL_STICKERS,
        /// Allows for sending messages in threads
        SEND_MESSAGES_IN_THREADS,
        /// Allows for launching activities (applications with the `EMBEDDED` flag) in a voice channel.
        USE_EMBEDDED_ACTIVITIES,
        /// Allows for timing out users to prevent them from sending or reacting to messages in chat and threads, and from speaking in voice and stage channels
        MODERATE_MEMBERS,
        /// Allows for viewing role subscription insights.
        VIEW_CREATOR_MONETIZATION_ANALYTICS,
        /// Allows for using soundboard in a voice channel.
        USE_SOUNDBOARD,
        /// Allows for creating emojis, stickers, and soundboard sounds, and editing and deleting those created by the current user
        CREATE_GUILD_EXPRESSIONS,
        /// Allows for creating scheduled events, and editing and deleting those created by the current user
        CREATE_EVENTS,
        /// Allows the usage of custom soundboards sounds from other servers
        USE_EXTERNAL_SOUNDS,
        /// Allows sending voice messages
        SEND_VOICE_MESSAGES,
        /// Allows sending polls
        SEND_POLLS,
        /// Allows user-installed apps to send public responses. When disabled, users will still be allowed to use their apps but the responses will be ephemeral. This only applies to apps not also installed to the server.
        USE_EXTERNAL_APPS,
    };

    /// https://discord.com/developers/docs/topics/opcodes-and-status-codes#opcodes-and-status-codes
    pub const GatewayCloseEventCodes = enum(u16) {
        /// A normal closure of the gateway. You may attempt to reconnect.
        NormalClosure = 1000,
        /// We're not sure what went wrong. Try reconnecting?
        UnknownError = 4000,
        /// You sent an invalid [Gateway opcode](https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-opcodes) or an invalid payload for an opcode. Don't do that!
        UnknownOpcode,
        /// You sent an invalid [payload](https://discord.com/developers/docs/topics/gateway#sending-payloads) to us. Don't do that!
        DecodeError,
        /// You sent us a payload prior to [identifying](https://discord.com/developers/docs/topics/gateway-events#identify), or this session has been invalidated.
        NotAuthenticated,
        /// The account token sent with your [identify payload](https://discord.com/developers/docs/topics/gateway-events#identify) is incorrect.
        AuthenticationFailed,
        /// You sent more than one identify payload. Don't do that!
        AlreadyAuthenticated,
        /// The sequence sent when [resuming](https://discord.com/developers/docs/topics/gateway-events#resume) the session was invalid. Reconnect and start a new session.
        InvalidSeq = 4007,
        /// Woah nelly! You're sending payloads to us too quickly. Slow it down! You will be disconnected on receiving this.
        RateLimited,
        /// Your session timed out. Reconnect and start a new one.
        SessionTimedOut,
        /// You sent us an invalid [shard when identifying](https://discord.com/developers/docs/topics/gateway#sharding).
        InvalidShard,
        /// The session would have handled too many guilds - you are required to [shard](https://discord.com/developers/docs/topics/gateway#sharding) your connection in order to connect.
        ShardingRequired,
        /// You sent an invalid version for the gateway.
        InvalidApiVersion,
        /// You sent an invalid intent for a [Gateway Intent](https://discord.com/developers/docs/topics/gateway#gateway-intents). You may have incorrectly calculated the bitwise value.
        InvalidIntents,
        /// You sent a disallowed intent for a [Gateway Intent](https://discord.com/developers/docs/topics/gateway#gateway-intents). You may have tried to specify an intent that you [have not enabled or are not approved for](https://discord.com/developers/docs/topics/gateway#privileged-intents).
        DisallowedIntents,
    };

    /// https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-opcodes
    pub const GatewayOpcodes = enum(u4) {
        /// An event was dispatched.
        Dispatch,
        /// Fired periodically by the client to keep the connection alive.
        Heartbeat,
        /// Starts a new session during the initial handshake.
        Identify,
        /// Update the client's presence.
        PresenceUpdate,
        /// Used to join/leave or move between voice channels.
        VoiceStateUpdate,
        /// Resume a previous session that was disconnected.
        Resume = 6,
        /// You should attempt to reconnect and resume immediately.
        Reconnect,
        /// Request information about offline guild members in a large guild.
        RequestGuildMembers,
        /// The session has been invalidated. You should reconnect and identify/resume accordingly.
        InvalidSession,
        /// Sent immediately after connecting, contains the `heartbeat_interval` to use.
        Hello,
        /// Sent in response to receiving a heartbeat to acknowledge that it has been received.
        HeartbeatACK,
    };

    pub const GatewayDispatchEventNames = union(enum) {
        APPLICATION_COMMAND_PERMISSIONS_UPDATE,
        AUTO_MODERATION_RULE_CREATE,
        AUTO_MODERATION_RULE_UPDATE,
        AUTO_MODERATION_RULE_DELETE,
        AUTO_MODERATION_ACTION_EXECUTION,
        CHANNEL_CREATE,
        CHANNEL_UPDATE,
        CHANNEL_DELETE,
        CHANNEL_PINS_UPDATE,
        THREAD_CREATE,
        THREAD_UPDATE,
        THREAD_DELETE,
        THREAD_LIST_SYNC,
        THREAD_MEMBER_UPDATE,
        THREAD_MEMBERS_UPDATE,
        GUILD_AUDIT_LOG_ENTRY_CREATE,
        GUILD_CREATE,
        GUILD_UPDATE,
        GUILD_DELETE,
        GUILD_BAN_ADD,
        GUILD_BAN_REMOVE,
        GUILD_EMOJIS_UPDATE,
        GUILD_STICKERS_UPDATE,
        GUILD_INTEGRATIONS_UPDATE,
        GUILD_MEMBER_ADD,
        GUILD_MEMBER_REMOVE,
        GUILD_MEMBER_UPDATE,
        GUILD_MEMBERS_CHUNK,
        GUILD_ROLE_CREATE,
        GUILD_ROLE_UPDATE,
        GUILD_ROLE_DELETE,
        GUILD_SCHEDULED_EVENT_CREATE,
        GUILD_SCHEDULED_EVENT_UPDATE,
        GUILD_SCHEDULED_EVENT_DELETE,
        GUILD_SCHEDULED_EVENT_USER_ADD,
        GUILD_SCHEDULED_EVENT_USER_REMOVE,
        INTEGRATION_CREATE,
        INTEGRATION_UPDATE,
        INTEGRATION_DELETE,
        INTERACTION_CREATE,
        INVITE_CREATE,
        INVITE_DELETE,
        MESSAGE_CREATE,
        MESSAGE_UPDATE,
        MESSAGE_DELETE,
        MESSAGE_DELETE_BULK,
        MESSAGE_REACTION_ADD,
        MESSAGE_REACTION_REMOVE,
        MESSAGE_REACTION_REMOVE_ALL,
        MESSAGE_REACTION_REMOVE_EMOJI,
        PRESENCE_UPDATE,
        STAGE_INSTANCE_CREATE,
        STAGE_INSTANCE_UPDATE,
        STAGE_INSTANCE_DELETE,
        TYPING_START,
        USER_UPDATE,
        VOICE_CHANNEL_EFFECT_SEND,
        VOICE_STATE_UPDATE,
        VOICE_SERVER_UPDATE,
        WEBHOOKS_UPDATE,
        ENTITLEMENT_CREATE,
        ENTITLEMENT_UPDATE,
        ENTITLEMENT_DELETE,
        MESSAGE_POLL_VOTE_ADD,
        MESSAGE_POLL_VOTE_REMOVE,

        READY,
        RESUMED,
    };

    /// https://discord.com/developers/docs/topics/gateway#list-of-intents
    pub const GatewayIntents = packed struct {
        pub fn toRaw(self: GatewayIntents) u32 {
            return @bitCast(self);
        }

        pub fn fromRaw(raw: u32) GatewayIntents {
            return @bitCast(raw);
        }

    pub fn jsonParse(allocator: std.mem.Allocator, src: anytype, _: std.json.ParseOptions) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .ignore_unknown_fields = true,
            .max_value_len = 0x1000,
        });
        if (value != .integer) @panic("Invalid value for bitfield");

        return fromRaw(@intCast(value.integer));
    }

    pub fn jsonParseFromValue(_: std.mem.Allocator, src: std.json.Value, _: std.json.ParseOptions) @This() {
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
    pub const Intents = GatewayIntents;

    /// https://discord.com/developers/docs/interactions/slash-commands#interaction-response-interactionresponsetype
    pub const InteractionResponseTypes = enum(u4) {
        /// ACK a `Ping`
        Pong = 1,
        /// Respond to an interaction with a message
        ChannelMessageWithSource = 4,
        /// ACK an interaction and edit a response later, the user sees a loading state
        DeferredChannelMessageWithSource = 5,
        /// For components, ACK an interaction and edit the original message later; the user does not see a loading state
        DeferredUpdateMessage = 6,
        /// For components, edit the message the component was attached to
        UpdateMessage = 7,
        /// For Application Command Options, send an autocomplete result
        ApplicationCommandAutocompleteResult = 8,
        /// For Command or Component interactions, send a Modal response
        Modal = 9,
        ///
        /// Respond to an interaction with an upgrade button, only available for apps with monetization enabled
        ///
        /// @deprecated You should migrate to the premium button components
        PremiumRequired = 10,
        ///
        /// Launch the Activity associated with the app.
        ///
        /// @remarks
        /// Only available for apps with Activities enabled
        LaunchActivity = 12,
    };

    pub const SortOrderTypes = enum {
        /// Sort forum posts by activity
        LatestActivity,
        /// Sort forum posts by creation time (from most recent to oldest)
        CreationDate,
    };

    pub const ForumLayout = enum {
        /// No default has been set for forum channel.
        NotSet,
        /// Display posts as a list.
        ListView,
        /// Display posts as a collection of tiles.
        GalleryView,
    };

    /// https://discord.com/developers/docs/reference#image-formatting
    /// json is only for stickers
    pub const ImageFormat = union(enum) {
        jpg,
        jpeg,
        png,
        webp,
        gif,
        json,
};

/// https://discord.com/developers/docs/reference#image-formatting
pub const ImageSize = isize;

pub const Locales = union(enum) {
    id,
    da,
    de,
    @"en-GB",
    @"en-US",
    @"es-ES",
    @"es-419",
    fr,
    hr,
    it,
    lt,
    hu,
    nl,
    no,
    pl,
    @"pt-BR",
    ro,
    fi,
    @"sv-SE",
    vi,
    tr,
    cs,
    el,
    bg,
    ru,
    uk,
    hi,
    th,
    @"zh-CN",
    ja,
    @"zh-TW",
    ko,
};

/// https://discord.com/developers/docs/topics/oauth2#shared-resources-oauth2-scopes
pub const OAuth2Scope = union(enum) {
    ///
    /// Allows your app to fetch data from a user's "Now Playing/Recently Played" list
    ///
    /// @remarks
    /// This scope is not currently available for apps
    ///
    @"activities.read",
    ///
    /// Allows your app to update a user's activity
    ///
    /// @remarks
    /// This scope not currently available for apps.
    ///
    @"activities.write",
    /// Allows your app to read build data for a user's applications
    @"applications.builds.read",
    ///
    /// Allows your app to upload/update builds for a user's applications
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"applications.builds.upload",
    /// Allows your app to add commands to a guild - included by default with the `bot` scope
    @"applications.commands",
    ///
    /// Allows your app to update its Application Commands via this bearer token
    ///
    /// @remarks
    /// This scope can only be used when using a [Client Credential Grant](https://discord.com/developers/docs/topics/oauth2#client-credentials-grant)
    ///
    @"applications.commands.update",
    /// Allows your app to update permissions for its commands in a guild a user has permissions to
    @"applications.commands.permissions.update",
    /// Allows your app to read entitlements for a user's applications
    @"applications.entitlements",
    /// Allows your app to read and update store data (SKUs, store listings, achievements, etc.) for a user's applications
    @"applications.store.update",
    /// For oauth2 bots, this puts the bot in the user's selected guild by default
    bot,
    /// Allows requests to [/users/@me/connections](https://discord.com/developers/docs/resources/user#get-user-connections)
    connections,
    ///
    /// Allows your app to see information about the user's DMs and group DMs
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"dm_channels.read",
    /// Adds the `email` filed to [/users/@me](https://discord.com/developers/docs/resources/user#get-current-user)
    email,
    /// Allows your app to join users to a group dm
    @"gdm.join",
    /// Allows requests to [/users/@me/guilds](https://discord.com/developers/docs/resources/user#get-current-user-guilds)
    guilds,
    /// Allows requests to [/guilds/{guild.id};/members/{user.id};](https://discord.com/developers/docs/resources/guild#add-guild-member)
    @"guilds.join",
    /// Allows requests to [/users/@me/guilds/{guild.id};/member](https://discord.com/developers/docs/resources/user#get-current-user-guild-member)
    @"guilds.members.read",
    ///
    /// Allows requests to [/users/@me](https://discord.com/developers/docs/resources/user#get-current-user)
    ///
    /// @remarks
    /// The return object from [/users/@me](https://discord.com/developers/docs/resources/user#get-current-user)
    /// does NOT contain the `email` field unless the scope `email` is also used
    ///
    identify,
    ///
    /// For local rpc server api access, this allows you to read messages from all client channels
    /// (otherwise restricted to channels/guilds your app creates)
    ///
    @"messages.read",
    ///
    /// Allows your app to know a user's friends and implicit relationships
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"relationships.read",
    /// Allows your app to update a user's connection and metadata for the app
    @"role_connections.write",
    ///
    ///For local rpc server access, this allows you to control a user's local  client
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    rpc,
    ///
    /// For local rpc server access, this allows you to update a user's activity
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"rpc.activities.write",
    ///
    /// For local rpc server api access, this allows you to receive notifications pushed out to the user
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"rpc.notifications.read",
    ///
    /// For local rpc server access, this allows you to read a user's voice settings and listen for voice events
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"rpc.voice.read",
    ///
    /// For local rpc server access, this allows you to update a user's voice settings
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    @"rpc.voice.write",
    ///
    /// Allows your app to connect to voice on user's behalf and see all the voice members
    ///
    /// @remarks
    ///This scope requires  approval to be used
    ///
    voice,
    /// Generate a webhook that is returned in the oauth token response for authorization code grants
    @"webhook.incoming",
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
