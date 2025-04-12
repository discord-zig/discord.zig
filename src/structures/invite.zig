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
    const Guild = @import("guild.zig").Guild;
    const Channel = @import("channel.zig").Channel;
    const Member = @import("member.zig").Member;
    const Application = @import("application.zig").Application;
    const MessageActivityTypes = @import("shared.zig").MessageActivityTypes;
    const ScheduledEvent = @import("scheduled_event.zig").ScheduledEvent;
    const TargetTypes = @import("shared.zig").TargetTypes;
    const Partial = @import("partial.zig").Partial;

    /// https://discord.com/developers/docs/resources/invite#invite-metadata-object
    pub const InviteMetadata = struct {
        /// The type of invite
        type: InviteType,
        /// The invite code (unique Id)
        code: []const u8,
        /// The guild this invite is for
        guild: ?Partial(Guild) = null,
        /// The channel this invite is for
        channel: ?Partial(Channel) = null,
        /// The user who created the invite
        inviter: ?User = null,
        /// The type of target for this voice channel invite
        target_type: ?TargetTypes = null,
        /// The target user for this invite
        target_user: ?User = null,
        /// The embedded application to open for this voice channel embedded application invite
        target_application: ?Partial(Application) = null,
        /// Approximate count of online members (only present when target_user is set)
        approximate_presence_count: ?isize = null,
        /// Approximate count of total members
        approximate_member_count: ?isize = null,
        /// The expiration date of this invite, returned from the `GET /invites/<code>` endpoint when `with_expiration` is `true`
        expires_at: ?[]const u8 = null,
        /// Stage instance data if there is a public Stage instance in the Stage channel this invite is for
        stage_instance: ?InviteStageInstance = null,
        /// guild scheduled event data
        guild_scheduled_event: ?ScheduledEvent = null,
        /// isize of times this invite has been used
        uses: isize,
        /// Max isize of times this invite can be used
        max_uses: isize,
        /// Duration (in seconds) after which the invite expires
        max_age: isize,
        /// Whether this invite only grants temporary membership
        temporary: bool,
        /// When this invite was created
        created_at: []const u8,
    };

    /// https://discord.com/developers/docs/resources/invite#invite-object
    pub const Invite = struct {
        /// The type of invite
        type: InviteType,
        /// The invite code (unique Id)
        code: []const u8,
        /// The guild this invite is for
        guild: ?Partial(Guild) = null,
        /// The channel this invite is for
        channel: ?Partial(Channel) = null,
        /// The user who created the invite
        inviter: ?User = null,
        /// The type of target for this voice channel invite
        target_type: ?TargetTypes = null,
        /// The target user for this invite
        target_user: ?User = null,
        /// The embedded application to open for this voice channel embedded application invite
        target_application: ?Partial(Application) = null,
        /// Approximate count of online members (only present when target_user is set)
        approximate_presence_count: ?isize = null,
        /// Approximate count of total members
        approximate_member_count: ?isize = null,
        /// The expiration date of this invite, returned from the `GET /invites/<code>` endpoint when `with_expiration` is `true`
        expires_at: ?[]const u8 = null,
        /// Stage instance data if there is a public Stage instance in the Stage channel this invite is for
        stage_instance: ?InviteStageInstance = null,
        /// guild scheduled event data
        guild_scheduled_event: ?ScheduledEvent = null,
};

pub const InviteType = enum {
    Guild,
    GroupDm,
    Friend,
};

pub const InviteStageInstance = struct {
    /// The members speaking in the Stage
    members: []Partial(Member),
    /// The isize of users in the Stage
    participant_count: isize,
    /// The isize of users speaking in the Stage
    speaker_count: isize,
    /// The topic of the Stage instance (1-120 characters)
    topic: []const u8,
};
