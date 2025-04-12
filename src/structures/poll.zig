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
    const User = @import("user.zig").User;
    const Emoji = @import("emoji.zig").Emoji;
    const Partial = @import("partial.zig").Partial;

    /// https://discord.com/developers/docs/resources/poll#poll-object
    pub const Poll = struct {
        /// The question of the poll. Only `text` is supported.
        question: PollMedia,
        /// Each of the answers available in the poll. There is a maximum of 10 answers per poll.
        answers: []PollAnswer,
        ///
        /// The time when the poll ends.
        ///
        /// @remarks
        /// `expiry` is marked as nullable to support non-expiring polls in the future, but all polls have an expiry currently.
        ///
        expiry: ?[]const u8 = null,
        /// Whether a user can select multiple answers
        allow_multiselect: bool,
        /// The layout type of the poll
        layout_type: PollLayoutType,
        ///
        /// The results of the poll
        ///
        /// @remarks
        /// This value will not be sent by discord under specific conditions where they don't fetch them on their backend. When this value is missing it should be interpreted as "Unknown results" and not as "No results"
        ///The results may not be totally accurate while the poll has not ended. When it ends discord will re-calculate all the results and set {@link PollResult.is_finalized}; to true
        ///
        results: ?PollResult = null,
    };

    /// https://discord.com/developers/docs/resources/poll#layout-type
    pub const PollLayoutType = enum(u4) {
        /// The default layout
        Default = 1,
    };

    /// https://discord.com/developers/docs/resources/poll#poll-media-object
    pub const PollMedia = struct {
        ///
        /// The text of the field
        ///
        /// @remarks
        /// `text` should always be non-null for both questions and answers, but this is subject to changes.
        /// The maximum length of `text` is 300 for the question, and 55 for any answer.
        ///
        text: ?[]const u8 = null,
        ///
        /// The emoji of the field
        ///
        /// @remarks
        /// When creating a poll answer with an emoji, one only needs to send either the `id` (custom emoji) or `name` (default emoji) as the only field.
        ///
        emoji: ?Partial(Emoji) = null,
    };

    /// https://discord.com/developers/docs/resources/poll#poll-answer-object
    pub const PollAnswer = struct {
        ///
        /// The id of the answer
        ///
        /// @remarks
        ///This id labels each answer. It starts at 1 and goes up sequentially.  recommend against depending on this value as is a implementation detail.
        ///
        answer_id: isize,
        /// The data of the answer
        poll_media: PollMedia,
    };

    pub const PollAnswerCount = struct {
        ///The {@link PollAnswer.answer_id | answer_id};
        id: isize,
        /// The isize of votes for this answer
        count: isize,
        /// Whether the current user voted for this answer
        me_voted: bool,
    };

    /// https://discord.com/developers/docs/resources/poll#poll-results-object
    pub const PollResult = struct {
        /// Whether the votes have been precisely counted
        is_finalized: bool,
        /// The counts for each answer
        answer_counts: []PollAnswerCount,
    };

    /// https://discord.com/developers/docs/resources/poll#get-answer-voters-response-body
    pub const GetAnswerVotesResponse = struct {
        /// Users who voted for this answer
        users: []User,
    };

    /// https://discord.com/developers/docs/topics/gateway-events#message-poll-vote-add
    pub const PollVoteAdd = struct {
        /// ID of the user. Usually a snowflake
        user_id: Snowflake,
        /// ID of the channel. Usually a snowflake
        channel_id: Snowflake,
        /// ID of the message. Usually a snowflake
        message_id: Snowflake,
        /// ID of the guild. Usually a snowflake
        guild_id: ?Snowflake = null,
        /// ID of the answer.
        answer_id: isize,
    };

    /// https://discord.com/developers/docs/topics/gateway-events#message-poll-vote-remove
    pub const PollVoteRemove = struct {
        /// ID of the user. Usually a snowflake
        user_id: Snowflake,
        /// ID of the channel. Usually a snowflake
        channel_id: Snowflake,
        /// ID of the message. Usually a snowflake
        message_id: Snowflake,
        /// ID of the guild. Usually a snowflake
        guild_id: ?Snowflake = null,
    /// ID of the answer.
    answer_id: isize,
};
