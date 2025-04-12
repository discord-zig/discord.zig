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

    /// https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-rule-object
    pub const AutoModerationRule = struct {
        /// The id of this rule
        id: Snowflake,
        /// The guild id of the rule
        guild_id: Snowflake,
        /// The name of the rule
        name: []const u8,
        /// The id of the user who created this rule.
        creator_id: Snowflake,
        /// Indicates in what event context a rule should be checked.
        event_type: AutoModerationEventTypes,
        /// The type of trigger for this rule
        trigger_type: AutoModerationTriggerTypes,
        /// The metadata used to determine whether a rule should be triggered.
        trigger_metadata: AutoModerationRuleTriggerMetadata,
        /// Actions which will execute whenever a rule is triggered.
        actions: []AutoModerationAction,
        /// Whether the rule is enabled.
        enabled: bool,
        /// The role ids that are whitelisted. Max 20.
        exempt_roles: [][]const u8,
        /// The channel ids that are whitelisted. Max 50.
        exempt_channels: [][]const u8,
    };

    pub const AutoModerationEventTypes = enum(u4) {
        /// When a user sends a message
        MessageSend = 1,
        /// Wen a member edits their profile
        MemberUpdate,
    };

    pub const AutoModerationTriggerTypes = enum(u4) {
        /// Check if content contains words from a user defined list of keywords. Max 6 per guild
        Keyword = 1,
        /// Check if content represents generic spam. Max 1 per guild
        Spam = 3,
        /// Check if content contains words from internal pre-defined word sets. Max 1 per guild
        KeywordPreset,
        /// Check if content contains more unique mentions than allowed. Max 1 per guild
        MentionSpam,
        /// Check if member profile contains words from a user defined list of keywords. Max 1 per guild
        MemberProfile,
    };

    pub const AutoModerationRuleTriggerMetadata = struct {
        ///
        /// The keywords needed to match.
        ///
        /// @remarks
        /// Only present with {@link AutoModerationTriggerTypes.Keyword}; and {@link AutoModerationTriggerTypes.MemberProfile};.
        ///
        /// Can have up to 1000 elements in the array and each []const u8 can have up to 60 characters
        ///
        keyword_filter: ?[][]const u8 = null,
        ///
        /// Regular expression patterns which will be matched against content.
        ///
        /// @remarks
        /// Only present with {@link AutoModerationTriggerTypes.Keyword}; and {@link AutoModerationTriggerTypes.MemberProfile};.
        ///
        /// Can have up to 10 elements in the array and each []const u8 can have up to 260 characters
        ///
        regex_patterns: [][]const u8,
        ///
        /// The pre-defined lists of words to match from.
        ///
        /// @remarks
        /// Only present with {@link AutoModerationTriggerTypes.KeywordPreset};.
        ///
        presets: ?[]AutoModerationRuleTriggerMetadataPresets = null,
        ///
        /// The substrings which will exempt from triggering the preset trigger type.
        ///
        /// @remarks
        /// Only present with {@link AutoModerationTriggerTypes.Keyword};, {@link AutoModerationTriggerTypes.KeywordPreset}; and {@link AutoModerationTriggerTypes.MemberProfile};.
        ///
        /// When used with {@link AutoModerationTriggerTypes.Keyword}; and {@link AutoModerationTriggerTypes.MemberProfile}; there can have up to 100 elements in the array and each []const u8 can have up to 60 characters.
        /// When used with {@link AutoModerationTriggerTypes.KeywordPreset}; there can have up to 1000 elements in the array and each []const u8 can have up to 60 characters.
        ///
        allow_list: ?[][]const u8 = null,
        ///
        /// Total isize of mentions (role & user) allowed per message.
        ///
        /// @remarks
        /// Only present with {@link AutoModerationTriggerTypes.MentionSpam};.
        ///
        /// Maximum of 50
        ///
        mention_total_limit: ?isize = null,
        ///
        /// Whether to automatically detect mention raids.
        ///
        /// @remarks
        /// Only present with {@link AutoModerationTriggerTypes.MentionSpam};.
        ///
        mention_raid_protection_enabled: ?bool = null,
    };

    pub const AutoModerationRuleTriggerMetadataPresets = enum(u4) {
        /// Words that may be considered forms of swearing or cursing
        Profanity = 1,
        /// Words that refer to sexually explicit behavior or activity
        SexualContent,
        /// Personal insults or words that may be considered hate speech
        Slurs,
    };

    pub const AutoModerationAction = struct {
        /// The type of action to take when a rule is triggered
        type: AutoModerationActionType,
        /// additional metadata needed during execution for this specific action type
        metadata: AutoModerationActionMetadata,
    };

    pub const AutoModerationActionType = enum(u4) {
        /// Blocks the content of a message according to the rule
        BlockMessage = 1,
        /// Logs user content to a specified channel
        SendAlertMessage,
        ///
        /// Times out user for specified duration
        ///
        /// @remarks
        /// A timeout action can only be set up for {@link AutoModerationTriggerTypes.Keyword}; and {@link AutoModerationTriggerTypes.MentionSpam}; rules.
        ///
        /// The `MODERATE_MEMBERS` permission is required to use the timeout action type.
        ///
        Timeout,
        /// prevents a member from using text, voice, or other interactions
        BlockMemberInteraction,
    };

    pub const AutoModerationActionMetadata = struct {
        /// The id of channel to which user content should be logged. Only in ActionType.SendAlertMessage
        channel_id: ?Snowflake = null,
        /// Additional explanation that will be shown to members whenever their message is blocked. Maximum of 150 characters. Only supported for AutoModerationActionType.BlockMessage
        custom_message: ?[]const u8 = null,
        /// Timeout duration in seconds maximum of 2419200 seconds (4 weeks). Only supported for TriggerType.Keyword && Only in ActionType.Timeout
        duration_seconds: ?isize = null,
    };

    /// https://discord.com/developers/docs/topics/gateway-events#auto-moderation-action-execution-auto-moderation-action-execution-event-fields
    pub const AutoModerationActionExecution = struct {
        /// The id of the guild
        guild_id: Snowflake,
        /// The id of the rule that was executed
        rule_id: Snowflake,
        /// The id of the user which generated the content which triggered the rule
        user_id: Snowflake,
        /// The content from the user
        content: []const u8,
        /// Action which was executed
        action: AutoModerationAction,
        /// The trigger type of the rule that was executed.
        rule_trigger_type: AutoModerationTriggerTypes,
        /// The id of the channel in which user content was posted
        channel_id: ?Snowflake = null,
        /// The id of the message. Will not exist if message was blocked by automod or content was not part of any message
        message_id: ?Snowflake = null,
        /// The id of any system auto moderation messages posted as a result of this action
        alert_system_message_id: ?Snowflake = null,
        /// The word or phrase that triggerred the rule.
        matched_keyword: ?[]const u8 = null,
        /// The substring in content that triggered the rule
        matched_content: ?[]const u8 = null,
};
