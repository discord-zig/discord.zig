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
    const AvatarDecorationData = @import("user.zig").AvatarDecorationData;

    /// https://discord.com/developers/docs/resources/guild#guild-member-object
    pub const Member = struct {
        /// Whether the user is deafened in voice channels
        deaf: ?bool = null,
        /// Whether the user is muted in voice channels
        mute: ?bool = null,
        /// Whether the user has not yet passed the guild's Membership Screening requirements
        pending: ?bool = null,
        /// The user this guild member represents
        user: ?User = null,
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
    };

    /// inherits
    pub const MemberWithUser = struct {
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
    };

    /// https://discord.com/developers/docs/resources/guild#add-guild-member-json-params
    pub const AddGuildMember = struct {
        /// access token of a user that has granted your app the `guilds.join` scope
        access_token: []const u8,
        /// Value to set user's nickname to. Requires MANAGE_NICKNAMES permission on the bot
        nick: ?[]const u8 = null,
        /// Array of role ids the member is assigned. Requires MANAGE_ROLES permission on the bot
        roles: ?[][]const u8 = null,
        /// Whether the user is muted in voice channels. Requires MUTE_MEMBERS permission on the bot
        mute: ?bool = null,
        /// Whether the user is deafened in voice channels. Requires DEAFEN_MEMBERS permission on the bot
        deaf: ?bool = null,
    };

    /// https://discord.com/developers/docs/resources/guild#modify-guild-member
    pub const ModifyGuildMember = struct {
        /// Value to set users nickname to. Requires the `MANAGE_NICKNAMES` permission
        nick: ?[]const u8 = null,
        /// Array of role ids the member is assigned. Requires the `MANAGE_ROLES` permission
        roles: ?Snowflake = null,
        /// Whether the user is muted in voice channels. Will throw a 400 if the user is not in a voice channel. Requires the `MUTE_MEMBERS` permission
        mute: ?bool = null,
        /// Whether the user is deafened in voice channels. Will throw a 400 if the user is not in a voice channel. Requires the `MOVE_MEMBERS` permission
        deaf: ?bool = null,
        /// Id of channel to move user to (if they are connected to voice). Requires the `MOVE_MEMBERS` permission
        channel_id: ?Snowflake = null,
        /// When the user's timeout will expire and the user will be able to communicate in the guild again (up to 28 days in the future), set to null to remove timeout. Requires the `MODERATE_MEMBERS` permission. The date must be given in a ISO string form.
        communication_disabled_until: ?[]const u8 = null,
        /// Set the flags for the guild member. Requires the `MANAGE_GUILD` or `MANAGE_ROLES` or the combination of `MODERATE_MEMBERS` and `KICK_MEMBERS` and `BAN_MEMBERS`
        flags: ?isize = null,
};
