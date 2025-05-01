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

    // shared.zig
    pub const PresenceStatus = @import("shared.zig").PresenceStatus;
    pub const PremiumTypes = @import("shared.zig").PremiumTypes;
    pub const UserFlags = @import("shared.zig").UserFlags;
    pub const PremiumUsageFlags = @import("shared.zig").PremiumUsageFlags;
    pub const PurchasedFlags = @import("shared.zig").PurchasedFlags;
    pub const MemberFlags = @import("shared.zig").MemberFlags;
    pub const ChannelFlags = @import("shared.zig").ChannelFlags;
    pub const RoleFlags = @import("shared.zig").RoleFlags;
    pub const AttachmentFlags = @import("shared.zig").AttachmentFlags;
    pub const SkuFlags = @import("shared.zig").SkuFlags;
    pub const MessageFlags = @import("shared.zig").MessageFlags;
    pub const ActivityFlags = @import("shared.zig").ActivityFlags;
    pub const IntegrationExpireBehaviors = @import("shared.zig").IntegrationExpireBehaviors;
    pub const TeamMembershipStates = @import("shared.zig").TeamMembershipStates;
    pub const ApplicationFlags = @import("shared.zig").ApplicationFlags;
    pub const MessageComponentTypes = @import("shared.zig").MessageComponentTypes;
    pub const TextStyles = @import("shared.zig").TextStyles;
    pub const ButtonStyles = @import("shared.zig").ButtonStyles;
    pub const AllowedMentionsTypes = @import("shared.zig").AllowedMentionsTypes;
    pub const WebhookTypes = @import("shared.zig").WebhookTypes;
    pub const EmbedTypes = @import("shared.zig").EmbedTypes;
    pub const DefaultMessageNotificationLevels = @import("shared.zig").DefaultMessageNotificationLevels;
    pub const ExplicitContentFilterLevels = @import("shared.zig").ExplicitContentFilterLevels;
    pub const VerificationLevels = @import("shared.zig").VerificationLevels;
    pub const GuildFeatures = @import("shared.zig").GuildFeatures;
    pub const MfaLevels = @import("shared.zig").MfaLevels;
    pub const SystemChannelFlags = @import("shared.zig").SystemChannelFlags;
    pub const PremiumTiers = @import("shared.zig").PremiumTiers;
    pub const GuildNsfwLevel = @import("shared.zig").GuildNsfwLevel;
    pub const ChannelTypes = @import("shared.zig").ChannelTypes;
    pub const OverwriteTypes = @import("shared.zig").OverwriteTypes;
    pub const VideoQualityModes = @import("shared.zig").VideoQualityModes;
    pub const ActivityTypes = @import("shared.zig").ActivityTypes;
    pub const MessageTypes = @import("shared.zig").MessageTypes;
    pub const MessageActivityTypes = @import("shared.zig").MessageActivityTypes;
    pub const StickerTypes = @import("shared.zig").StickerTypes;
    pub const StickerFormatTypes = @import("shared.zig").StickerFormatTypes;
    pub const InteractionTypes = @import("shared.zig").InteractionTypes;
    pub const ApplicationCommandOptionTypes = @import("shared.zig").ApplicationCommandOptionTypes;
    pub const AuditLogEvents = @import("shared.zig").AuditLogEvents;
    pub const ScheduledEventPrivacyLevel = @import("shared.zig").ScheduledEventPrivacyLevel;
    pub const ScheduledEventEntityType = @import("shared.zig").ScheduledEventEntityType;
    pub const ScheduledEventStatus = @import("shared.zig").ScheduledEventStatus;
    pub const TargetTypes = @import("shared.zig").TargetTypes;
    pub const ApplicationCommandTypes = @import("shared.zig").ApplicationCommandTypes;
    pub const ApplicationCommandPermissionTypes = @import("shared.zig").ApplicationCommandPermissionTypes;
    pub const BitwisePermissionFlags = @import("shared.zig").BitwisePermissionFlags;
    pub const PermissionStrings = @import("shared.zig").PermissionStrings;
    pub const GatewayCloseEventCodes = @import("shared.zig").GatewayCloseEventCodes;
    pub const GatewayOpcodes = @import("shared.zig").GatewayOpcodes;
    pub const GatewayDispatchEventNames = @import("shared.zig").GatewayDispatchEventNames;
    pub const InteractionResponseTypes = @import("shared.zig").InteractionResponseTypes;
    pub const SortOrderTypes = @import("shared.zig").SortOrderTypes;
    pub const ForumLayout = @import("shared.zig").ForumLayout;
    pub const ImageFormat = @import("shared.zig").ImageFormat;
    pub const ImageSize = @import("shared.zig").ImageSize;
    pub const Locales = @import("shared.zig").Locales;
    pub const OAuth2Scope = @import("shared.zig").OAuth2Scope;
    // partial.zig
    pub const Partial = @import("partial.zig").Partial;
    // snowflake.zig
    pub const discord_epoch = @import("snowflake.zig").discord_epoch;
    pub const Snowflake = @import("snowflake.zig").Snowflake;
    // events.zig
    pub const GuildMembersChunk = @import("events.zig").GuildMembersChunk;
    pub const ChannelPinsUpdate = @import("events.zig").ChannelPinsUpdate;
    pub const GuildRoleDelete = @import("events.zig").GuildRoleDelete;
    pub const GuildBanAddRemove = @import("events.zig").GuildBanAddRemove;
    pub const MessageReactionRemove = @import("events.zig").MessageReactionRemove;
    pub const MessageReactionAdd = @import("events.zig").MessageReactionAdd;
    pub const VoiceServerUpdate = @import("events.zig").VoiceServerUpdate;
    pub const VoiceChannelEffectSend = @import("events.zig").VoiceChannelEffectSend;
    pub const VoiceChannelEffectAnimationType = @import("events.zig").VoiceChannelEffectAnimationType;
    pub const InviteCreate = @import("events.zig").InviteCreate;
    pub const Hello = @import("events.zig").Hello;
    pub const Ready = @import("events.zig").Ready;
    pub const UnavailableGuild = @import("events.zig").UnavailableGuild;
    pub const MessageDeleteBulk = @import("events.zig").MessageDeleteBulk;
    pub const Template = @import("events.zig").Template;
    pub const TemplateSerializedSourceGuild = @import("events.zig").TemplateSerializedSourceGuild;
    pub const GuildMemberAdd = @import("events.zig").GuildMemberAdd;
    pub const MessageDelete = @import("events.zig").MessageDelete;
    pub const ThreadMembersUpdate = @import("events.zig").ThreadMembersUpdate;
    pub const ThreadMemberUpdate = @import("events.zig").ThreadMemberUpdate;
    pub const GuildRoleCreate = @import("events.zig").GuildRoleCreate;
    pub const GuildEmojisUpdate = @import("events.zig").GuildEmojisUpdate;
    pub const GuildStickersUpdate = @import("events.zig").GuildStickersUpdate;
    pub const GuildMemberUpdate = @import("events.zig").GuildMemberUpdate;
    pub const MessageReactionRemoveAll = @import("events.zig").MessageReactionRemoveAll;
    pub const GuildRoleUpdate = @import("events.zig").GuildRoleUpdate;
    pub const ScheduledEventUserAdd = @import("events.zig").ScheduledEventUserAdd;
    pub const MessageReactionRemoveEmoji = @import("events.zig").MessageReactionRemoveEmoji;
    pub const GuildMemberRemove = @import("events.zig").GuildMemberRemove;
    pub const Ban = @import("events.zig").Ban;
    pub const ScheduledEventUserRemove = @import("events.zig").ScheduledEventUserRemove;
    pub const InviteDelete = @import("events.zig").InviteDelete;
    pub const VoiceRegion = @import("events.zig").VoiceRegion;
    pub const GuildWidgetSettings = @import("events.zig").GuildWidgetSettings;
    pub const ModifyChannel = @import("events.zig").ModifyChannel;
    pub const CreateGuildEmoji = @import("events.zig").CreateGuildEmoji;
    pub const ModifyGuildEmoji = @import("events.zig").ModifyGuildEmoji;
    pub const CreateGuildChannel = @import("events.zig").CreateGuildChannel;
    pub const CreateMessage = @import("events.zig").CreateMessage;
    pub const ModifyGuildWelcomeScreen = @import("events.zig").ModifyGuildWelcomeScreen;
    pub const FollowAnnouncementChannel = @import("events.zig").FollowAnnouncementChannel;
    pub const EditChannelPermissionOverridesOptions = @import("events.zig").EditChannelPermissionOverridesOptions;
    pub const CreateWebhook = @import("events.zig").CreateWebhook;
    pub const CreateForumPostWithMessage = @import("events.zig").CreateForumPostWithMessage;
    pub const ArchivedThreads = @import("events.zig").ArchivedThreads;
    pub const ActiveThreads = @import("events.zig").ActiveThreads;
    pub const VanityUrl = @import("events.zig").VanityUrl;
    pub const PrunedCount = @import("events.zig").PrunedCount;
    pub const TeamMemberRole = @import("events.zig").TeamMemberRole;
    pub const BulkBan = @import("events.zig").BulkBan;

    // application.zig
    pub const Application = @import("application.zig").Application;
    pub const ApplicationIntegrationTypeConfiguration = @import("application.zig").ApplicationIntegrationTypeConfiguration;
    pub const ApplicationIntegrationType = @import("application.zig").ApplicationIntegrationType;
    pub const InstallParams = @import("application.zig").InstallParams;
    pub const ModifyApplication = @import("application.zig").ModifyApplication;
    pub const ApplicationEventWebhookStatus = @import("application.zig").ApplicationEventWebhookStatus;
    pub const WebhookEventType = @import("application.zig").WebhookEventType;
    // attachment.zig
    pub const Attachment = @import("attachment.zig").Attachment;
    // auditlog.zig
    pub const AuditLog = @import("auditlog.zig").AuditLog;
    pub const AuditLogEntry = @import("auditlog.zig").AuditLogEntry;
    pub const OptionalAuditEntryInfo = @import("auditlog.zig").OptionalAuditEntryInfo;
    pub const AuditLogChange = @import("auditlog.zig").AuditLogChange;
    // automod.zig
    pub const AutoModerationRule = @import("automod.zig").AutoModerationRule;
    pub const AutoModerationEventTypes = @import("automod.zig").AutoModerationEventTypes;
    pub const AutoModerationTriggerTypes = @import("automod.zig").AutoModerationTriggerTypes;
    pub const AutoModerationRuleTriggerMetadata = @import("automod.zig").AutoModerationRuleTriggerMetadata;
    pub const AutoModerationRuleTriggerMetadataPresets = @import("automod.zig").AutoModerationRuleTriggerMetadataPresets;
    pub const AutoModerationAction = @import("automod.zig").AutoModerationAction;
    pub const AutoModerationActionType = @import("automod.zig").AutoModerationActionType;
    pub const AutoModerationActionMetadata = @import("automod.zig").AutoModerationActionMetadata;
    pub const AutoModerationActionExecution = @import("automod.zig").AutoModerationActionExecution;
    // channel.zig
    pub const TypingStart = @import("channel.zig").TypingStart;
    pub const Channel = @import("channel.zig").Channel;
    pub const WelcomeScreen = @import("channel.zig").WelcomeScreen;
    pub const WelcomeScreenChannel = @import("channel.zig").WelcomeScreenChannel;
    pub const StageInstance = @import("channel.zig").StageInstance;
    pub const Overwrite = @import("channel.zig").Overwrite;
    pub const FollowedChannel = @import("channel.zig").FollowedChannel;
    pub const ForumTag = @import("channel.zig").ForumTag;
    pub const DefaultReactionEmoji = @import("channel.zig").DefaultReactionEmoji;
    pub const ModifyGuildChannelPositions = @import("channel.zig").ModifyGuildChannelPositions;
    pub const CreateChannelInvite = @import("channel.zig").CreateChannelInvite;
    // command.zig
    pub const ApplicationCommand = @import("command.zig").ApplicationCommand;
    pub const CreateApplicationCommand = @import("command.zig").CreateApplicationCommand;
    pub const LocaleMap = @import("command.zig").LocaleMap;
    pub const InteractionEntryPointCommandHandlerType = @import("command.zig").InteractionEntryPointCommandHandlerType;
    pub const ApplicationCommandOption = @import("command.zig").ApplicationCommandOption;
    pub const ApplicationCommandOptionChoice = @import("command.zig").ApplicationCommandOptionChoice;
    pub const GuildApplicationCommandPermissions = @import("command.zig").GuildApplicationCommandPermissions;
    pub const ApplicationCommandPermissions = @import("command.zig").ApplicationCommandPermissions;
    // component.zig
    pub const Button = @import("component.zig").Button;
    pub const SelectOption = @import("component.zig").SelectOption;
    pub const DefaultValue = @import("component.zig").DefaultValue;
    pub const SelectMenuString = @import("component.zig").SelectMenuString;
    pub const SelectMenuUsers = @import("component.zig").SelectMenuUsers;
    pub const SelectMenuRoles = @import("component.zig").SelectMenuRoles;
    pub const SelectMenuUsersAndRoles = @import("component.zig").SelectMenuUsersAndRoles;
    pub const SelectMenuChannels = @import("component.zig").SelectMenuChannels;
    pub const SelectMenu = @import("component.zig").SelectMenu;
    pub const InputTextStyles = @import("component.zig").InputTextStyles;
    pub const InputText = @import("component.zig").InputText;
    pub const MessageComponent = @import("component.zig").MessageComponent;
    // embed.zig
    pub const Embed = @import("embed.zig").Embed;
    pub const EmbedAuthor = @import("embed.zig").EmbedAuthor;
    pub const EmbedField = @import("embed.zig").EmbedField;
    pub const EmbedFooter = @import("embed.zig").EmbedFooter;
    pub const EmbedImage = @import("embed.zig").EmbedImage;
    pub const EmbedProvider = @import("embed.zig").EmbedProvider;
    pub const EmbedThumbnail = @import("embed.zig").EmbedThumbnail;
    pub const EmbedVideo = @import("embed.zig").EmbedVideo;
    // emoji.zig
    pub const Emoji = @import("emoji.zig").Emoji;
    // gateway.zig
    pub const GetGatewayBot = @import("gateway.zig").GetGatewayBot;
    pub const SessionStartLimit = @import("gateway.zig").SessionStartLimit;
    pub const PresenceUpdate = @import("gateway.zig").PresenceUpdate;
    pub const Activity = @import("gateway.zig").Activity;
    pub const ActivityInstance = @import("gateway.zig").ActivityInstance;
    pub const ActivityLocation = @import("gateway.zig").ActivityLocation;
    pub const ActivityLocationKind = @import("gateway.zig").ActivityLocationKind;
    pub const ClientStatus = @import("gateway.zig").ClientStatus;
    pub const ActivityTimestamps = @import("gateway.zig").ActivityTimestamps;
    pub const ActivityEmoji = @import("gateway.zig").ActivityEmoji;
    pub const ActivityParty = @import("gateway.zig").ActivityParty;
    pub const ActivityAssets = @import("gateway.zig").ActivityAssets;
    pub const ActivitySecrets = @import("gateway.zig").ActivitySecrets;
    pub const ActivityButton = @import("gateway.zig").ActivityButton;
    // guild.zig
    pub const Guild = @import("guild.zig").Guild;
    pub const VoiceState = @import("guild.zig").VoiceState;
    pub const GuildWidget = @import("guild.zig").GuildWidget;
    pub const GuildPreview = @import("guild.zig").GuildPreview;
    pub const CreateGuild = @import("guild.zig").CreateGuild;
    pub const ModifyGuild = @import("guild.zig").ModifyGuild;
    pub const CreateGuildBan = @import("guild.zig").CreateGuildBan;
    pub const GetGuildPruneCountQuery = @import("guild.zig").GetGuildPruneCountQuery;
    pub const BeginGuildPrune = @import("guild.zig").BeginGuildPrune;
    pub const ModifyGuildOnboarding = @import("guild.zig").ModifyGuildOnboarding;
    pub const GuildOnboarding = @import("guild.zig").GuildOnboarding;
    pub const GuildOnboardingPrompt = @import("guild.zig").GuildOnboardingPrompt;
    pub const GuildOnboardingPromptOption = @import("guild.zig").GuildOnboardingPromptOption;
    pub const GuildOnboardingPromptType = @import("guild.zig").GuildOnboardingPromptType;
    pub const GuildOnboardingMode = @import("guild.zig").GuildOnboardingMode;
    // integration.zig
    pub const Integration = @import("integration.zig").Integration;
    pub const IntegrationAccount = @import("integration.zig").IntegrationAccount;
    pub const IntegrationApplication = @import("integration.zig").IntegrationApplication;
    pub const IntegrationCreateUpdate = @import("integration.zig").IntegrationCreateUpdate;
    pub const IntegrationDelete = @import("integration.zig").IntegrationDelete;
    pub const GuildIntegrationsUpdate = @import("integration.zig").GuildIntegrationsUpdate;
    pub const InteractionContextType = @import("integration.zig").InteractionContextType;
    // invite.zig
    pub const InviteMetadata = @import("invite.zig").InviteMetadata;
    pub const Invite = @import("invite.zig").Invite;
    pub const InviteType = @import("invite.zig").InviteType;
    pub const InviteStageInstance = @import("invite.zig").InviteStageInstance;
    // member.zig
    pub const Member = @import("member.zig").Member;
    pub const MemberWithUser = @import("member.zig").MemberWithUser;
    pub const AddGuildMember = @import("member.zig").AddGuildMember;
    pub const ModifyGuildMember = @import("member.zig").ModifyGuildMember;
    // message.zig
    pub const Message = @import("message.zig").Message;
    pub const MessageCall = @import("message.zig").MessageCall;
    pub const ChannelMention = @import("message.zig").ChannelMention;
    pub const Reaction = @import("message.zig").Reaction;
    pub const ReactionType = @import("message.zig").ReactionType;
    pub const ReactionCountDetails = @import("message.zig").ReactionCountDetails;
    pub const MessageActivity = @import("message.zig").MessageActivity;
    pub const MessageReference = @import("message.zig").MessageReference;
    pub const MessageReferenceType = @import("message.zig").MessageReferenceType;
    pub const MessageSnapshot = @import("message.zig").MessageSnapshot;
    pub const MessageInteraction = @import("message.zig").MessageInteraction;
    pub const MessageInteractionMetadata = @import("message.zig").MessageInteractionMetadata;
    pub const AllowedMentions = @import("message.zig").AllowedMentions;
    pub const GetMessagesQuery = @import("message.zig").GetMessagesQuery;
    // monetization.zig
    pub const Entitlement = @import("monetization.zig").Entitlement;
    pub const EntitlementType = @import("monetization.zig").EntitlementType;
    pub const Sku = @import("monetization.zig").Sku;
    pub const SkuType = @import("monetization.zig").SkuType;
    pub const CreateTestEntitlement = @import("monetization.zig").CreateTestEntitlement;
    // oauth.zig
    pub const TokenExchangeAuthorizationCode = @import("oauth.zig").TokenExchangeAuthorizationCode;
    pub const TokenExchangeRefreshToken = @import("oauth.zig").TokenExchangeRefreshToken;
    pub const TokenExchangeClientCredentials = @import("oauth.zig").TokenExchangeClientCredentials;
    pub const AccessTokenResponse = @import("oauth.zig").AccessTokenResponse;
    // poll.zig
    pub const Poll = @import("poll.zig").Poll;
    pub const PollLayoutType = @import("poll.zig").PollLayoutType;
    pub const PollMedia = @import("poll.zig").PollMedia;
    pub const PollAnswer = @import("poll.zig").PollAnswer;
    pub const PollAnswerCount = @import("poll.zig").PollAnswerCount;
    pub const PollResult = @import("poll.zig").PollResult;
    pub const GetAnswerVotesResponse = @import("poll.zig").GetAnswerVotesResponse;
    pub const PollVoteAdd = @import("poll.zig").PollVoteAdd;
    pub const PollVoteRemove = @import("poll.zig").PollVoteRemove;
    // role.zig
    pub const Role = @import("role.zig").Role;
    pub const RoleTags = @import("role.zig").RoleTags;
    pub const CreateGuildRole = @import("role.zig").CreateGuildRole;
    pub const ModifyGuildRole = @import("role.zig").ModifyGuildRole;
    // scheduled_event.zig
    pub const ScheduledEvent = @import("scheduled_event.zig").ScheduledEvent;
    pub const ScheduledEventEntityMetadata = @import("scheduled_event.zig").ScheduledEventEntityMetadata;
    pub const ScheduledEventRecurrenceRule = @import("scheduled_event.zig").ScheduledEventRecurrenceRule;
    pub const ScheduledEventRecurrenceRuleFrequency = @import("scheduled_event.zig").ScheduledEventRecurrenceRuleFrequency;
    pub const ScheduledEventRecurrenceRuleWeekday = @import("scheduled_event.zig").ScheduledEventRecurrenceRuleWeekday;
    pub const ScheduledEventRecurrenceRuleNWeekday = @import("scheduled_event.zig").ScheduledEventRecurrenceRuleNWeekday;
    pub const ScheduledEventRecurrenceRuleMonth = @import("scheduled_event.zig").ScheduledEventRecurrenceRuleMonth;
    // sticker.zig
    pub const Sticker = @import("sticker.zig").Sticker;
    pub const StickerItem = @import("sticker.zig").StickerItem;
    pub const StickerPack = @import("sticker.zig").StickerPack;
    pub const CreateModifyGuildSticker = @import("sticker.zig").CreateModifyGuildSticker;
    // team.zig
    pub const Team = @import("team.zig").Team;
    pub const TeamMember = @import("team.zig").TeamMember;
    // thread.zig
    pub const ThreadMetadata = @import("thread.zig").ThreadMetadata;
    pub const ThreadMember = @import("thread.zig").ThreadMember;
    pub const ListActiveThreads = @import("thread.zig").ListActiveThreads;
    pub const ListArchivedThreads = @import("thread.zig").ListArchivedThreads;
    pub const ThreadListSync = @import("thread.zig").ThreadListSync;
    pub const StartThreadFromMessage = @import("thread.zig").StartThreadFromMessage;
    pub const StartThreadWithoutMessage = @import("thread.zig").StartThreadWithoutMessage;
    pub const CreateForumAndMediaThreadMessage = @import("thread.zig").CreateForumAndMediaThreadMessage;
    pub const StartThreadInForumOrMediaChannel = @import("thread.zig").StartThreadInForumOrMediaChannel;
    // user.zig
    pub const User = @import("user.zig").User;
    pub const AvatarDecorationData = @import("user.zig").AvatarDecorationData;
    pub const TokenExchange = @import("user.zig").TokenExchange;
    pub const TokenRevocation = @import("user.zig").TokenRevocation;
    pub const CurrentAuthorization = @import("user.zig").CurrentAuthorization;
    pub const Connection = @import("user.zig").Connection;
    pub const ConnectionServiceType = @import("user.zig").ConnectionServiceType;
    pub const ConnectionVisibility = @import("user.zig").ConnectionVisibility;
    pub const ApplicationRoleConnection = @import("user.zig").ApplicationRoleConnection;
    pub const ModifyCurrentUser = @import("user.zig").ModifyCurrentUser;
    // webhook.zig
    pub const WebhookUpdate = @import("webhook.zig").WebhookUpdate;
    pub const Webhook = @import("webhook.zig").Webhook;
    pub const IncomingWebhook = @import("webhook.zig").IncomingWebhook;
    pub const ApplicationWebhook = @import("webhook.zig").ApplicationWebhook;

    /// https://discord.com/developers/docs/topics/gateway#payloads-gateway-payload-structure

    pub fn GatewayPayload(comptime T: type) type {
        return struct {
            /// opcode for the payload
            op: isize,
            /// Event data
            d: ?T = null,
            /// Sequence isize, used for resuming sessions and heartbeats
            s: ?isize = null,
            /// The event name for this payload
            t: ?[]const u8 = null,
            //    t: ?GatewayDispatchEventNames = null,
        };
    }
