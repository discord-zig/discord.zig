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
    const TeamMembershipStates = @import("shared.zig").TeamMembershipStates;

    /// https://discord.com/developers/docs/topics/teams#data-models-team-object
    pub const Team = struct {
        /// Hash of the image of the team's icon
        icon: ?[]const u8 = null,
    /// Unique ID of the team
    id: Snowflake,
    /// Members of the team
    members: []TeamMember,
    /// User ID of the current team owner
    owner_user_id: Snowflake,
    /// Name of the team
    name: []const u8,
};

/// https://discord.com/developers/docs/topics/teams#data-models-team-members-object
pub const TeamMember = struct {
    /// The user's membership state on the team
    membership_state: TeamMembershipStates,
    /// The id of the parent team of which they are a member
    team_id: Snowflake,
    /// The avatar, discriminator, id, username, and global_name of the user
    /// TODO: needs fixing
    user: struct {
        /// Unique ID of the user
        id: Snowflake,
        /// The user's username, not unique across the platform
        username: []const u8,
        /// The user's display name, if it is set. For bots, this is the application name
        global_name: []const u8,
        /// The user's discord-tag
        discriminator: []const u8,
        /// The user's avatar hash
        avatar: []const u8,
    },
};
