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
    const InteractionTypes = @import("shared.zig").InteractionTypes;
    const Guild = @import("guild.zig").Guild;
    const Attachment = @import("attachment.zig").Attachment;
    const Message = @import("message.zig").Message;
    const Channel = @import("channel.zig").Channel;
    const User = @import("user.zig").User;
    const Role = @import("role.zig").Role;
    const AvatarDecorationData = @import("user.zig").AvatarDecorationData;
    const Partial = @import("partial.zig").Partial;
    const ApplicationCommandOptionTypes = @import("shared.zig").ApplicationCommandOptionTypes;
    const MessageComponentTypes = @import("shared.zig").MessageComponentTypes;
    const ChannelTypes = @import("shared.zig").ChannelTypes;
    const MessageComponent = @import("message.zig").MessageComponent;
    const ApplicationCommandTypes = @import("shared.zig").ApplicationCommandTypes;
    const InteractionResponseTypes = @import("shared.zig").InteractionResponseTypes;
    const InteractionContextType = @import("command.zig").InteractionContextType;
    const Entitlement = @import("monetization.zig").Entitlement;
    const Record = @import("../utils/json.zig").Record;

    pub const Interaction = struct {
        /// Id of the interaction
        id: Snowflake,
        /// Id of the application this interaction is for
        application_id: Snowflake,
        /// The type of interaction
        type: InteractionTypes,
        /// Guild that the interaction was sent from
        guild: ?Partial(Guild) = null,
        /// The guild it was sent from
        guild_id: ?Snowflake = null,
        /// The channel it was sent from
        channel: Partial(Channel),
        ///
        /// The ID of channel it was sent from
        ///
        /// @remarks
        /// It is recommended that you begin using this channel field to identify the source channel of the interaction as they may deprecate the existing channel_id field in the future.
        ///
        channel_id: ?Snowflake = null,
        /// Guild member data for the invoking user, including permissions
        member: ?InteractionMember = null,
        /// User object for the invoking user, if invoked in a DM
        user: ?User = null,
        /// A continuation token for responding to the interaction
        token: []const u8,
        /// Read-only property, always `1`
        version: 1,
        /// For the message the button was attached to
        message: ?Message = null,
        /// the command data payload
        data: ?InteractionData = null,
        /// The selected language of the invoking user
        locale: ?[]const u8 = null,
        /// The guild's preferred locale, if invoked in a guild
        guild_locale: ?[]const u8 = null,
        /// The computed permissions for a bot or app in the context of a specific interaction (including channel overwrites)
        app_permissions: []const u8,
        /// For monetized apps, any entitlements for the invoking user, representing access to premium SKUs
        entitlements: []Entitlement,
        // Mapping of installation contexts that the interaction was authorized for to related user or guild IDs.
        // authorizing_integration_owners: Partial(AutoArrayHashMap(ApplicationIntegrationType, []const u8)),
        /// Context where the interaction was triggered from
        context: ?InteractionContextType = null,
    };

    /// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-callback-interaction-callback-response-object
    pub const InteractionCallbackResponse = struct {
        /// The interaction object associated with the interaction response
        interaction: InteractionCallback,
        /// The resource that was created by the interaction response.
        resource: ?InteractionResource = null,
    };

    /// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-callback-interaction-callback-object
    pub const InteractionCallback = struct {
        /// ID of the interaction
        id: Snowflake,
        /// Interaction type
        type: InteractionTypes,
        /// Instance ID of the Activity if one was launched or joined
        activity_instance_id: ?Snowflake = null,
        /// ID of the message that was created by the interaction
        response_message_id: ?Snowflake = null,
        /// Whether or not the message is in a loading state
        response_message_loading: ?bool = null,
        /// Whether or not the response message was ephemeral
        response_message_ephemeral: ?bool = null,
    };

    /// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-callback-interaction-callback-resource-object
    pub const InteractionResource = struct {
        type: InteractionResponseTypes,
        ///
        /// Represents the Activity launched by this interaction.
        ///
        /// @remarks
        /// Only present if type is `LAUNCH_ACTIVITY`.
        ///
        activity_instance: ?ActivityInstanceResource = null,
        ///
        /// Message created by the interaction.
        ///
        /// @remarks
        /// Only present if type is either `CHANNEL_MESSAGE_WITH_SOURCE` or `UPDATE_MESSAGE`.
        ///
        message: ?Message = null,
    };

    /// https://discord.com/developers/docs/interactions/receiving-and-responding#interaction-callback-interaction-callback-activity-instance-resource
    pub const ActivityInstanceResource = struct {
        /// Instance ID of the Activity if one was launched or joined.
        id: Snowflake,
    };

    /// https://discord.com/developers/docs/resources/guild#guild-member-object
    pub const InteractionMember = struct {
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
        /// when the user's timeout will expire and the user will be able to communicate in the guild again (set null to remove timeout), null or a time in the past if the user is not timed out
        communication_disabled_until: ?[]const u8 = null,
        /// Guild member flags
        flags: isize,
        /// data for the member's guild avatar decoration
        avatar_decoration_data: ?AvatarDecorationData = null,
        /// The user object for this member
        user: User,
        /// Total permissions of the member in the channel, including overwrites, returned when in the interaction object
        permissions: []const u8,
    };

    pub const InteractionData = struct {
        /// The type of component
        component_type: ?MessageComponentTypes = null,
        /// The custom id provided for this component.
        custom_id: ?Snowflake = null,
        /// The components if its a Modal Submit interaction.
        components: ?[]MessageComponent = null,
        /// The values chosen by the user.
        values: ?[][]const u8 = null,
        /// The Id of the invoked command
        id: Snowflake,
        /// The name of the invoked command
        name: []const u8,
        /// the type of the invoked command
        type: ApplicationCommandTypes,
        /// Converted users + roles + channels + attachments
        resolved: ?struct {
            /// The Ids and Message objects
        messages: ?Record(Message) = null,
            /// The Ids and User objects
        users: ?Record(User) = null,
            // The Ids and partial Member objects
            //    members: ?Record(Omit(InteractionMember, .{ "user", "deaf", "mute" })) = null,
            /// The Ids and Role objects
        roles: ?Record(Role) = null,
            /// The Ids and partial Channel objects
            channels: ?Record(struct {
                id: Snowflake,
                type: ChannelTypes,
        name: ?[]const u8 = null,
        permissions: ?[]const u8 = null,
            }),
            /// The ids and attachment objects
            attachments: Record(Attachment),
        },
        /// The params + values from the user
        options: ?[]InteractionDataOption = null,
        /// The target id if this is a context menu command.
        target_id: ?Snowflake = null,
        /// the id of the guild the command is registered to
        guild_id: ?Snowflake = null,
    };

    pub const InteractionDataOption = struct {
        /// Name of the parameter
        name: []const u8,
        /// Value of application command option type
        type: ApplicationCommandOptionTypes,
        /// Value of the option resulting from user input
        value: ?union { string: []const u8, bool: bool, integer: isize } = null,
        /// Present if this option is a group or subcommand
        options: ?[]InteractionDataOption = null,
        /// `true` if this option is the currently focused option for autocomplete
        focused: ?bool = null,
};
