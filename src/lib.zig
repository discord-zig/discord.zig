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

// NUKE USING NAMESPACE
// structures/types.zig
pub const PresenceStatus = @import("structures/types.zig").PresenceStatus;
pub const PremiumTypes = @import("structures/types.zig").PremiumTypes;
pub const UserFlags = @import("structures/types.zig").UserFlags;
pub const PremiumUsageFlags = @import("structures/types.zig").PremiumUsageFlags;
pub const PurchasedFlags = @import("structures/types.zig").PurchasedFlags;
pub const MemberFlags = @import("structures/types.zig").MemberFlags;
pub const ChannelFlags = @import("structures/types.zig").ChannelFlags;
pub const RoleFlags = @import("structures/types.zig").RoleFlags;
pub const AttachmentFlags = @import("structures/types.zig").AttachmentFlags;
pub const SkuFlags = @import("structures/types.zig").SkuFlags;
pub const MessageFlags = @import("structures/types.zig").MessageFlags;
pub const ActivityFlags = @import("structures/types.zig").ActivityFlags;
pub const IntegrationExpireBehaviors = @import("structures/types.zig").IntegrationExpireBehaviors;
pub const TeamMembershipStates = @import("structures/types.zig").TeamMembershipStates;
pub const ApplicationFlags = @import("structures/types.zig").ApplicationFlags;
pub const MessageComponentTypes = @import("structures/types.zig").MessageComponentTypes;
pub const TextStyles = @import("structures/types.zig").TextStyles;
pub const ButtonStyles = @import("structures/types.zig").ButtonStyles;
pub const AllowedMentionsTypes = @import("structures/types.zig").AllowedMentionsTypes;
pub const WebhookTypes = @import("structures/types.zig").WebhookTypes;
pub const EmbedTypes = @import("structures/types.zig").EmbedTypes;
pub const DefaultMessageNotificationLevels = @import("structures/types.zig").DefaultMessageNotificationLevels;
pub const ExplicitContentFilterLevels = @import("structures/types.zig").ExplicitContentFilterLevels;
pub const VerificationLevels = @import("structures/types.zig").VerificationLevels;
pub const GuildFeatures = @import("structures/types.zig").GuildFeatures;
pub const MfaLevels = @import("structures/types.zig").MfaLevels;
pub const SystemChannelFlags = @import("structures/types.zig").SystemChannelFlags;
pub const PremiumTiers = @import("structures/types.zig").PremiumTiers;
pub const GuildNsfwLevel = @import("structures/types.zig").GuildNsfwLevel;
pub const ChannelTypes = @import("structures/types.zig").ChannelTypes;
pub const OverwriteTypes = @import("structures/types.zig").OverwriteTypes;
pub const VideoQualityModes = @import("structures/types.zig").VideoQualityModes;
pub const ActivityTypes = @import("structures/types.zig").ActivityTypes;
pub const MessageTypes = @import("structures/types.zig").MessageTypes;
pub const MessageActivityTypes = @import("structures/types.zig").MessageActivityTypes;
pub const StickerTypes = @import("structures/types.zig").StickerTypes;
pub const StickerFormatTypes = @import("structures/types.zig").StickerFormatTypes;
pub const InteractionTypes = @import("structures/types.zig").InteractionTypes;
pub const ApplicationCommandOptionTypes = @import("structures/types.zig").ApplicationCommandOptionTypes;
pub const AuditLogEvents = @import("structures/types.zig").AuditLogEvents;
pub const ScheduledEventPrivacyLevel = @import("structures/types.zig").ScheduledEventPrivacyLevel;
pub const ScheduledEventEntityType = @import("structures/types.zig").ScheduledEventEntityType;
pub const ScheduledEventStatus = @import("structures/types.zig").ScheduledEventStatus;
pub const TargetTypes = @import("structures/types.zig").TargetTypes;
pub const ApplicationCommandTypes = @import("structures/types.zig").ApplicationCommandTypes;
pub const ApplicationCommandPermissionTypes = @import("structures/types.zig").ApplicationCommandPermissionTypes;
pub const BitwisePermissionFlags = @import("structures/types.zig").BitwisePermissionFlags;
pub const PermissionStrings = @import("structures/types.zig").PermissionStrings;
pub const GatewayCloseEventCodes = @import("structures/types.zig").GatewayCloseEventCodes;
pub const GatewayOpcodes = @import("structures/types.zig").GatewayOpcodes;
pub const GatewayDispatchEventNames = @import("structures/types.zig").GatewayDispatchEventNames;
pub const InteractionResponseTypes = @import("structures/types.zig").InteractionResponseTypes;
pub const SortOrderTypes = @import("structures/types.zig").SortOrderTypes;
pub const ForumLayout = @import("structures/types.zig").ForumLayout;
pub const ImageFormat = @import("structures/types.zig").ImageFormat;
pub const ImageSize = @import("structures/types.zig").ImageSize;
pub const Locales = @import("structures/types.zig").Locales;
pub const OAuth2Scope = @import("structures/types.zig").OAuth2Scope;
pub const Partial = @import("structures/types.zig").Partial;
pub const discord_epoch = @import("structures/types.zig").discord_epoch;
pub const Snowflake = @import("structures/types.zig").Snowflake;
pub const GuildMembersChunk = @import("structures/types.zig").GuildMembersChunk;
pub const ChannelPinsUpdate = @import("structures/types.zig").ChannelPinsUpdate;
pub const GuildRoleDelete = @import("structures/types.zig").GuildRoleDelete;
pub const GuildBanAddRemove = @import("structures/types.zig").GuildBanAddRemove;
pub const MessageReactionRemove = @import("structures/types.zig").MessageReactionRemove;
pub const MessageReactionAdd = @import("structures/types.zig").MessageReactionAdd;
pub const VoiceServerUpdate = @import("structures/types.zig").VoiceServerUpdate;
pub const VoiceChannelEffectSend = @import("structures/types.zig").VoiceChannelEffectSend;
pub const VoiceChannelEffectAnimationType = @import("structures/types.zig").VoiceChannelEffectAnimationType;
pub const InviteCreate = @import("structures/types.zig").InviteCreate;
pub const Hello = @import("structures/types.zig").Hello;
pub const Ready = @import("structures/types.zig").Ready;
pub const UnavailableGuild = @import("structures/types.zig").UnavailableGuild;
pub const MessageDeleteBulk = @import("structures/types.zig").MessageDeleteBulk;
pub const Template = @import("structures/types.zig").Template;
pub const TemplateSerializedSourceGuild = @import("structures/types.zig").TemplateSerializedSourceGuild;
pub const GuildMemberAdd = @import("structures/types.zig").GuildMemberAdd;
pub const MessageDelete = @import("structures/types.zig").MessageDelete;
pub const ThreadMembersUpdate = @import("structures/types.zig").ThreadMembersUpdate;
pub const ThreadMemberUpdate = @import("structures/types.zig").ThreadMemberUpdate;
pub const GuildRoleCreate = @import("structures/types.zig").GuildRoleCreate;
pub const GuildEmojisUpdate = @import("structures/types.zig").GuildEmojisUpdate;
pub const GuildStickersUpdate = @import("structures/types.zig").GuildStickersUpdate;
pub const GuildMemberUpdate = @import("structures/types.zig").GuildMemberUpdate;
pub const MessageReactionRemoveAll = @import("structures/types.zig").MessageReactionRemoveAll;
pub const GuildRoleUpdate = @import("structures/types.zig").GuildRoleUpdate;
pub const ScheduledEventUserAdd = @import("structures/types.zig").ScheduledEventUserAdd;
pub const MessageReactionRemoveEmoji = @import("structures/types.zig").MessageReactionRemoveEmoji;
pub const GuildMemberRemove = @import("structures/types.zig").GuildMemberRemove;
pub const Ban = @import("structures/types.zig").Ban;
pub const ScheduledEventUserRemove = @import("structures/types.zig").ScheduledEventUserRemove;
pub const InviteDelete = @import("structures/types.zig").InviteDelete;
pub const VoiceRegion = @import("structures/types.zig").VoiceRegion;
pub const GuildWidgetSettings = @import("structures/types.zig").GuildWidgetSettings;
pub const ModifyChannel = @import("structures/types.zig").ModifyChannel;
pub const CreateGuildEmoji = @import("structures/types.zig").CreateGuildEmoji;
pub const ModifyGuildEmoji = @import("structures/types.zig").ModifyGuildEmoji;
pub const CreateGuildChannel = @import("structures/types.zig").CreateGuildChannel;
pub const CreateMessage = @import("structures/types.zig").CreateMessage;
pub const ModifyGuildWelcomeScreen = @import("structures/types.zig").ModifyGuildWelcomeScreen;
pub const FollowAnnouncementChannel = @import("structures/types.zig").FollowAnnouncementChannel;
pub const EditChannelPermissionOverridesOptions = @import("structures/types.zig").EditChannelPermissionOverridesOptions;
pub const CreateWebhook = @import("structures/types.zig").CreateWebhook;
pub const CreateForumPostWithMessage = @import("structures/types.zig").CreateForumPostWithMessage;
pub const ArchivedThreads = @import("structures/types.zig").ArchivedThreads;
pub const ActiveThreads = @import("structures/types.zig").ActiveThreads;
pub const VanityUrl = @import("structures/types.zig").VanityUrl;
pub const PrunedCount = @import("structures/types.zig").PrunedCount;
pub const TeamMemberRole = @import("structures/types.zig").TeamMemberRole;
pub const BulkBan = @import("structures/types.zig").BulkBan;
pub const Application = @import("structures/types.zig").Application;
pub const ApplicationIntegrationTypeConfiguration = @import("structures/types.zig").ApplicationIntegrationTypeConfiguration;
pub const ApplicationIntegrationType = @import("structures/types.zig").ApplicationIntegrationType;
pub const InstallParams = @import("structures/types.zig").InstallParams;
pub const ModifyApplication = @import("structures/types.zig").ModifyApplication;
pub const ApplicationEventWebhookStatus = @import("structures/types.zig").ApplicationEventWebhookStatus;
pub const WebhookEventType = @import("structures/types.zig").WebhookEventType;
pub const Attachment = @import("structures/types.zig").Attachment;
pub const AuditLog = @import("structures/types.zig").AuditLog;
pub const AuditLogEntry = @import("structures/types.zig").AuditLogEntry;
pub const OptionalAuditEntryInfo = @import("structures/types.zig").OptionalAuditEntryInfo;
pub const AuditLogChange = @import("structures/types.zig").AuditLogChange;
pub const AutoModerationRule = @import("structures/types.zig").AutoModerationRule;
pub const AutoModerationEventTypes = @import("structures/types.zig").AutoModerationEventTypes;
pub const AutoModerationTriggerTypes = @import("structures/types.zig").AutoModerationTriggerTypes;
pub const AutoModerationRuleTriggerMetadata = @import("structures/types.zig").AutoModerationRuleTriggerMetadata;
pub const AutoModerationRuleTriggerMetadataPresets = @import("structures/types.zig").AutoModerationRuleTriggerMetadataPresets;
pub const AutoModerationAction = @import("structures/types.zig").AutoModerationAction;
pub const AutoModerationActionType = @import("structures/types.zig").AutoModerationActionType;
pub const AutoModerationActionMetadata = @import("structures/types.zig").AutoModerationActionMetadata;
pub const AutoModerationActionExecution = @import("structures/types.zig").AutoModerationActionExecution;
pub const TypingStart = @import("structures/types.zig").TypingStart;
pub const Channel = @import("structures/types.zig").Channel;
pub const WelcomeScreen = @import("structures/types.zig").WelcomeScreen;
pub const WelcomeScreenChannel = @import("structures/types.zig").WelcomeScreenChannel;
pub const StageInstance = @import("structures/types.zig").StageInstance;
pub const Overwrite = @import("structures/types.zig").Overwrite;
pub const FollowedChannel = @import("structures/types.zig").FollowedChannel;
pub const ForumTag = @import("structures/types.zig").ForumTag;
pub const DefaultReactionEmoji = @import("structures/types.zig").DefaultReactionEmoji;
pub const ModifyGuildChannelPositions = @import("structures/types.zig").ModifyGuildChannelPositions;
pub const CreateChannelInvite = @import("structures/types.zig").CreateChannelInvite;
pub const ApplicationCommand = @import("structures/types.zig").ApplicationCommand;
pub const CreateApplicationCommand = @import("structures/types.zig").CreateApplicationCommand;
pub const ApplicationCommandOption = @import("structures/types.zig").ApplicationCommandOption;
pub const ApplicationCommandOptionChoice = @import("structures/types.zig").ApplicationCommandOptionChoice;
pub const GuildApplicationCommandPermissions = @import("structures/types.zig").GuildApplicationCommandPermissions;
pub const ApplicationCommandPermissions = @import("structures/types.zig").ApplicationCommandPermissions;
pub const Button = @import("structures/types.zig").Button;
pub const SelectOption = @import("structures/types.zig").SelectOption;
pub const DefaultValue = @import("structures/types.zig").DefaultValue;
pub const SelectMenuString = @import("structures/types.zig").SelectMenuString;
pub const SelectMenuUsers = @import("structures/types.zig").SelectMenuUsers;
pub const SelectMenuRoles = @import("structures/types.zig").SelectMenuRoles;
pub const SelectMenuUsersAndRoles = @import("structures/types.zig").SelectMenuUsersAndRoles;
pub const SelectMenuChannels = @import("structures/types.zig").SelectMenuChannels;
pub const SelectMenu = @import("structures/types.zig").SelectMenu;
pub const InputTextStyles = @import("structures/types.zig").InputTextStyles;
pub const InputText = @import("structures/types.zig").InputText;
pub const MessageComponent = @import("structures/types.zig").MessageComponent;
pub const Embed = @import("structures/types.zig").Embed;
pub const EmbedAuthor = @import("structures/types.zig").EmbedAuthor;
pub const EmbedField = @import("structures/types.zig").EmbedField;
pub const EmbedFooter = @import("structures/types.zig").EmbedFooter;
pub const EmbedImage = @import("structures/types.zig").EmbedImage;
pub const EmbedProvider = @import("structures/types.zig").EmbedProvider;
pub const EmbedThumbnail = @import("structures/types.zig").EmbedThumbnail;
pub const EmbedVideo = @import("structures/types.zig").EmbedVideo;
pub const Emoji = @import("structures/types.zig").Emoji;
pub const GetGatewayBot = @import("structures/types.zig").GetGatewayBot;
pub const SessionStartLimit = @import("structures/types.zig").SessionStartLimit;
pub const PresenceUpdate = @import("structures/types.zig").PresenceUpdate;
pub const Activity = @import("structures/types.zig").Activity;
pub const ActivityInstance = @import("structures/types.zig").ActivityInstance;
pub const ActivityLocation = @import("structures/types.zig").ActivityLocation;
pub const ActivityLocationKind = @import("structures/types.zig").ActivityLocationKind;
pub const ClientStatus = @import("structures/types.zig").ClientStatus;
pub const ActivityTimestamps = @import("structures/types.zig").ActivityTimestamps;
pub const ActivityEmoji = @import("structures/types.zig").ActivityEmoji;
pub const ActivityParty = @import("structures/types.zig").ActivityParty;
pub const ActivityAssets = @import("structures/types.zig").ActivityAssets;
pub const ActivitySecrets = @import("structures/types.zig").ActivitySecrets;
pub const ActivityButton = @import("structures/types.zig").ActivityButton;
pub const Guild = @import("structures/types.zig").Guild;
pub const VoiceState = @import("structures/types.zig").VoiceState;
pub const GuildWidget = @import("structures/types.zig").GuildWidget;
pub const GuildPreview = @import("structures/types.zig").GuildPreview;
pub const CreateGuild = @import("structures/types.zig").CreateGuild;
pub const ModifyGuild = @import("structures/types.zig").ModifyGuild;
pub const CreateGuildBan = @import("structures/types.zig").CreateGuildBan;
pub const GetGuildPruneCountQuery = @import("structures/types.zig").GetGuildPruneCountQuery;
pub const BeginGuildPrune = @import("structures/types.zig").BeginGuildPrune;
pub const ModifyGuildOnboarding = @import("structures/types.zig").ModifyGuildOnboarding;
pub const GuildOnboarding = @import("structures/types.zig").GuildOnboarding;
pub const GuildOnboardingPrompt = @import("structures/types.zig").GuildOnboardingPrompt;
pub const GuildOnboardingPromptOption = @import("structures/types.zig").GuildOnboardingPromptOption;
pub const GuildOnboardingPromptType = @import("structures/types.zig").GuildOnboardingPromptType;
pub const GuildOnboardingMode = @import("structures/types.zig").GuildOnboardingMode;
pub const Integration = @import("structures/types.zig").Integration;
pub const IntegrationAccount = @import("structures/types.zig").IntegrationAccount;
pub const IntegrationApplication = @import("structures/types.zig").IntegrationApplication;
pub const IntegrationCreateUpdate = @import("structures/types.zig").IntegrationCreateUpdate;
pub const IntegrationDelete = @import("structures/types.zig").IntegrationDelete;
pub const GuildIntegrationsUpdate = @import("structures/types.zig").GuildIntegrationsUpdate;
pub const InteractionContextType = @import("structures/types.zig").InteractionContextType;
pub const InviteMetadata = @import("structures/types.zig").InviteMetadata;
pub const Invite = @import("structures/types.zig").Invite;
pub const InviteType = @import("structures/types.zig").InviteType;
pub const InviteStageInstance = @import("structures/types.zig").InviteStageInstance;
pub const Member = @import("structures/types.zig").Member;
pub const MemberWithUser = @import("structures/types.zig").MemberWithUser;
pub const AddGuildMember = @import("structures/types.zig").AddGuildMember;
pub const ModifyGuildMember = @import("structures/types.zig").ModifyGuildMember;
pub const Message = @import("structures/types.zig").Message;
pub const MessageCall = @import("structures/types.zig").MessageCall;
pub const ChannelMention = @import("structures/types.zig").ChannelMention;
pub const Reaction = @import("structures/types.zig").Reaction;
pub const ReactionType = @import("structures/types.zig").ReactionType;
pub const ReactionCountDetails = @import("structures/types.zig").ReactionCountDetails;
pub const MessageActivity = @import("structures/types.zig").MessageActivity;
pub const MessageReference = @import("structures/types.zig").MessageReference;
pub const MessageReferenceType = @import("structures/types.zig").MessageReferenceType;
pub const MessageSnapshot = @import("structures/types.zig").MessageSnapshot;
pub const MessageInteraction = @import("structures/types.zig").MessageInteraction;
pub const MessageInteractionMetadata = @import("structures/types.zig").MessageInteractionMetadata;
pub const AllowedMentions = @import("structures/types.zig").AllowedMentions;
pub const GetMessagesQuery = @import("structures/types.zig").GetMessagesQuery;
pub const Entitlement = @import("structures/types.zig").Entitlement;
pub const EntitlementType = @import("structures/types.zig").EntitlementType;
pub const Sku = @import("structures/types.zig").Sku;
pub const SkuType = @import("structures/types.zig").SkuType;
pub const CreateTestEntitlement = @import("structures/types.zig").CreateTestEntitlement;
pub const TokenExchangeAuthorizationCode = @import("structures/types.zig").TokenExchangeAuthorizationCode;
pub const TokenExchangeRefreshToken = @import("structures/types.zig").TokenExchangeRefreshToken;
pub const TokenExchangeClientCredentials = @import("structures/types.zig").TokenExchangeClientCredentials;
pub const AccessTokenResponse = @import("structures/types.zig").AccessTokenResponse;
pub const Poll = @import("structures/types.zig").Poll;
pub const PollLayoutType = @import("structures/types.zig").PollLayoutType;
pub const PollMedia = @import("structures/types.zig").PollMedia;
pub const PollAnswer = @import("structures/types.zig").PollAnswer;
pub const PollAnswerCount = @import("structures/types.zig").PollAnswerCount;
pub const PollResult = @import("structures/types.zig").PollResult;
pub const GetAnswerVotesResponse = @import("structures/types.zig").GetAnswerVotesResponse;
pub const PollVoteAdd = @import("structures/types.zig").PollVoteAdd;
pub const PollVoteRemove = @import("structures/types.zig").PollVoteRemove;
pub const Role = @import("structures/types.zig").Role;
pub const RoleTags = @import("structures/types.zig").RoleTags;
pub const CreateGuildRole = @import("structures/types.zig").CreateGuildRole;
pub const ModifyGuildRole = @import("structures/types.zig").ModifyGuildRole;
pub const ScheduledEvent = @import("structures/types.zig").ScheduledEvent;
pub const ScheduledEventEntityMetadata = @import("structures/types.zig").ScheduledEventEntityMetadata;
pub const ScheduledEventRecurrenceRule = @import("structures/types.zig").ScheduledEventRecurrenceRule;
pub const ScheduledEventRecurrenceRuleFrequency = @import("structures/types.zig").ScheduledEventRecurrenceRuleFrequency;
pub const ScheduledEventRecurrenceRuleWeekday = @import("structures/types.zig").ScheduledEventRecurrenceRuleWeekday;
pub const ScheduledEventRecurrenceRuleNWeekday = @import("structures/types.zig").ScheduledEventRecurrenceRuleNWeekday;
pub const ScheduledEventRecurrenceRuleMonth = @import("structures/types.zig").ScheduledEventRecurrenceRuleMonth;
pub const Sticker = @import("structures/types.zig").Sticker;
pub const StickerItem = @import("structures/types.zig").StickerItem;
pub const StickerPack = @import("structures/types.zig").StickerPack;
pub const CreateModifyGuildSticker = @import("structures/types.zig").CreateModifyGuildSticker;
pub const Team = @import("structures/types.zig").Team;
pub const TeamMember = @import("structures/types.zig").TeamMember;
pub const ThreadMetadata = @import("structures/types.zig").ThreadMetadata;
pub const ThreadMember = @import("structures/types.zig").ThreadMember;
pub const ListActiveThreads = @import("structures/types.zig").ListActiveThreads;
pub const ListArchivedThreads = @import("structures/types.zig").ListArchivedThreads;
pub const ThreadListSync = @import("structures/types.zig").ThreadListSync;
pub const StartThreadFromMessage = @import("structures/types.zig").StartThreadFromMessage;
pub const StartThreadWithoutMessage = @import("structures/types.zig").StartThreadWithoutMessage;
pub const CreateForumAndMediaThreadMessage = @import("structures/types.zig").CreateForumAndMediaThreadMessage;
pub const StartThreadInForumOrMediaChannel = @import("structures/types.zig").StartThreadInForumOrMediaChannel;
pub const User = @import("structures/types.zig").User;
pub const AvatarDecorationData = @import("structures/types.zig").AvatarDecorationData;
pub const TokenExchange = @import("structures/types.zig").TokenExchange;
pub const TokenRevocation = @import("structures/types.zig").TokenRevocation;
pub const CurrentAuthorization = @import("structures/types.zig").CurrentAuthorization;
pub const Connection = @import("structures/types.zig").Connection;
pub const ConnectionServiceType = @import("structures/types.zig").ConnectionServiceType;
pub const ConnectionVisibility = @import("structures/types.zig").ConnectionVisibility;
pub const ApplicationRoleConnection = @import("structures/types.zig").ApplicationRoleConnection;
pub const ModifyCurrentUser = @import("structures/types.zig").ModifyCurrentUser;
pub const WebhookUpdate = @import("structures/types.zig").WebhookUpdate;
pub const Webhook = @import("structures/types.zig").Webhook;
pub const IncomingWebhook = @import("structures/types.zig").IncomingWebhook;
pub const ApplicationWebhook = @import("structures/types.zig").ApplicationWebhook;
pub const GatewayPayload = @import("structures/types.zig").GatewayPayload;
// END USING NAMESPACE

pub const CacheTables = @import("cache/cache.zig").CacheTables;
pub const CacheLike = @import("cache/cache.zig").CacheLike;
pub const DefaultCache = @import("cache/cache.zig").DefaultCache;

pub const Permissions = @import("utils/permissions.zig").Permissions;
pub const Shard = @import("shard/shard.zig").Shard;
pub const zjson = @compileError("Deprecated.");

pub const Internal = @import("utils/core.zig");
const GatewayDispatchEvent = Internal.GatewayDispatchEvent;
const GatewayBotInfo = @import("shard/util.zig").GatewayBotInfo;
const Log = Internal.Log;

// sharder
pub const Sharder = @import("shard/sharder.zig").ShardManager;

pub const cache = @import("cache/cache.zig");

pub const FetchReq = @import("http/http.zig").FetchReq;
pub const FileData = @import("http/http.zig").FileData;

const std = @import("std");
const mem = std.mem;
const http = std.http;
const json = std.json;

pub fn CustomisedSession(comptime Table: cache.TableTemplate) type {
    return struct {
        const Self = @This();

        allocator: mem.Allocator,
        sharder: Sharder(Table),
        token: []const u8,

        pub fn init(allocator: mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .sharder = undefined,
                .token = undefined,
            };
        }

        pub fn deinit(self: *Self) void {
            self.sharder.deinit();
        }

        pub fn start(self: *Self, settings: struct {
            token: []const u8,
            intents: Intents,
            options: struct {
                spawn_shard_delay: u64 = 5300,
                total_shards: usize = 1,
                shard_start: usize = 0,
                shard_end: usize = 1,
            },
            run: GatewayDispatchEvent,
            log: Log,
            cache: cache.TableTemplate,
        }) !void {
            if (!std.mem.startsWith(u8, settings.token, "Bot")) {
                var buffer = [_]u8{undefined} ** 128;
                const printed = try std.fmt.bufPrint(&buffer, "Bot {s}", .{settings.token});
                self.token = printed;
            } else {
                self.token = settings.token;
            }

            var req = FetchReq.init(self.allocator, self.token);
            defer req.deinit();

            const res = try req.makeRequest(.GET, "/gateway/bot", null);
            const body = try req.body.toOwnedSlice();
            defer self.allocator.free(body);

            // check status idk
            if (res.status != http.Status.ok) {
                @panic("we are cooked\n"); // check your token dumbass
            }

            const parsed = try json.parseFromSlice(GatewayBotInfo, self.allocator, body, .{});
            defer parsed.deinit();

            self.sharder = try Sharder(Table).init(self.allocator, .{
                .token = self.token,
                    .intents = settings.intents,
                .run = settings.run,
                .options = Sharder(Table).SessionOptions{
                    .info = parsed.value,
                    .shard_start = settings.options.shard_start,
                    .shard_end = @intCast(parsed.value.shards),
                    .total_shards = @intCast(parsed.value.shards),
                    .spawn_shard_delay = settings.options.spawn_shard_delay,
                },
                .log = settings.log,
                .cache = settings.cache,
            });

            try self.sharder.spawnShards();
        }
    };
}

// defaults
const DefaultTable = cache.TableTemplate{};
pub const Session = CustomisedSession(DefaultTable);

pub fn init(allocator: mem.Allocator) Session {
    return Session.init(allocator);
}

pub fn deinit(self: *Session) void {
    self.deinit();
}

pub const GatewayIntents = @import("./shard/intents.zig").GatewayIntents;
pub const Intents = @import("./shard/intents.zig").Intents;

pub fn start(self: *Session, settings: struct {
    token: []const u8,
    intents: Intents,
    options: struct {
        spawn_shard_delay: u64 = 5300,
        total_shards: usize = 1,
        shard_start: usize = 0,
        shard_end: usize = 1,
    },
    run: GatewayDispatchEvent,
    log: Log,
    cache: cache.TableTemplate,
}) !void {
    return self.start(settings);
}
