const Partial = @import("partial.zig").Partial;
const Snowflake = @import("snowflake.zig").Snowflake;
const Emoji = @import("emoji.zig").Emoji;
const ButtonStyles = @import("shared.zig").ButtonStyles;
const ChannelTypes = @import("shared.zig").ChannelTypes;
const MessageComponentTypes = @import("shared.zig").MessageComponentTypes;

const zjson = @import("../json.zig");
const std = @import("std");

/// https://discord.com/developers/docs/interactions/message-components#buttons
pub const Button = struct {
    /// 2 for a button
    type: MessageComponentTypes,
    /// A button style
    style: ButtonStyles,
    /// Text that appears on the button; max 80 characters
    label: ?[]const u8,
    /// name, id, and animated
    emoji: Partial(Emoji),
    /// Developer-defined identifier for the button; max 100 characters
    custom_id: ?[]const u8,
    /// Identifier for a purchasable SKU, only available when using premium-style buttons
    sku_id: ?Snowflake,
    /// URL for link-style buttons
    url: ?[]const u8,
    /// Whether the button is disabled (defaults to false)
    disabled: ?bool,
};

pub const SelectOption = struct {
    /// User-facing name of the option; max 100 characters
    label: []const u8,
    /// Dev-defined value of the option; max 100 characters
    value: []const u8,
    /// Additional description of the option; max 100 characters
    description: ?[]const u8,
    /// id, name, and animated
    emoji: ?Partial(Emoji),
    /// Will show this option as selected by default
    default: ?bool,
};

pub const DefaultValue = struct {
    /// ID of a user, role, or channel
    id: Snowflake,
    /// Type of value that id represents. Either "user", "role", or "channel"
    type: union(enum) { user, role, channel },
};

/// https://discord.com/developers/docs/interactions/message-components#select-menus
pub const SelectMenuString = struct {
    /// Type of select menu component (text: 3, user: 5, role: 6, mentionable: 7, channels: 8)
    type: MessageComponentTypes,
    /// ID for the select menu; max 100 characters
    custom_id: []const u8,
    /// Specified choices in a select menu (only required and available for string selects (type 3); max 25
    /// * options is required for string select menus (component type 3), and unavailable for all other select menu components.
    options: ?[]SelectOption,
    /// Placeholder text if nothing is selected; max 150 characters
    placeholder: ?[]const u8,
    /// Minimum number of items that must be chosen (defaults to 1); min 0, max 25
    min_values: ?usize,
    /// Maximum number of items that can be chosen (defaults to 1); max 25
    max_values: ?usize,
    /// Whether select menu is disabled (defaults to false)
    disabled: ?bool,
};

/// https://discord.com/developers/docs/interactions/message-components#select-menus
pub const SelectMenuUsers = struct {
    /// Type of select menu component (text: 3, user: 5, role: 6, mentionable: 7, channels: 8)
    type: MessageComponentTypes,
    /// ID for the select menu; max 100 characters
    custom_id: []const u8,
    /// Placeholder text if nothing is selected; max 150 characters
    placeholder: ?[]const u8,
    /// List of default values for auto-populated select menu components; number of default values must be in the range defined by min_values and max_values
    /// *** default_values is only available for auto-populated select menu components, which include user (5), role (6), mentionable (7), and channel (8) components.
    default_values: ?[]DefaultValue,
    /// Minimum number of items that must be chosen (defaults to 1); min 0, max 25
    min_values: ?usize,
    /// Maximum number of items that can be chosen (defaults to 1); max 25
    max_values: ?usize,
    /// Whether select menu is disabled (defaults to false)
    disabled: ?bool,
};

/// https://discord.com/developers/docs/interactions/message-components#select-menus
pub const SelectMenuRoles = struct {
    /// Type of select menu component (text: 3, user: 5, role: 6, mentionable: 7, channels: 8)
    type: MessageComponentTypes,
    /// ID for the select menu; max 100 characters
    custom_id: []const u8,
    /// Placeholder text if nothing is selected; max 150 characters
    placeholder: ?[]const u8,
    /// List of default values for auto-populated select menu components; number of default values must be in the range defined by min_values and max_values
    /// *** default_values is only available for auto-populated select menu components, which include user (5), role (6), mentionable (7), and channel (8) components.
    default_values: ?[]DefaultValue,
    /// Minimum number of items that must be chosen (defaults to 1); min 0, max 25
    min_values: ?usize,
    /// Maximum number of items that can be chosen (defaults to 1); max 25
    max_values: ?usize,
    /// Whether select menu is disabled (defaults to false)
    disabled: ?bool,
};

/// https://discord.com/developers/docs/interactions/message-components#select-menus
pub const SelectMenuUsersAndRoles = struct {
    /// Type of select menu component (text: 3, user: 5, role: 6, mentionable: 7, channels: 8)
    type: MessageComponentTypes,
    /// ID for the select menu; max 100 characters
    custom_id: []const u8,
    /// Placeholder text if nothing is selected; max 150 characters
    placeholder: ?[]const u8,
    /// List of default values for auto-populated select menu components; number of default values must be in the range defined by min_values and max_values
    /// *** default_values is only available for auto-populated select menu components, which include user (5), role (6), mentionable (7), and channel (8) components.
    default_values: ?[]DefaultValue,
    /// Minimum number of items that must be chosen (defaults to 1); min 0, max 25
    min_values: ?usize,
    /// Maximum number of items that can be chosen (defaults to 1); max 25
    max_values: ?usize,
    /// Whether select menu is disabled (defaults to false)
    disabled: ?bool,
};

/// https://discord.com/developers/docs/interactions/message-components#select-menus
pub const SelectMenuChannels = struct {
    /// Type of select menu component (text: 3, user: 5, role: 6, mentionable: 7, channels: 8)
    type: MessageComponentTypes,
    /// ID for the select menu; max 100 characters
    custom_id: []const u8,
    /// List of channel types to include in the channel select component (type 8)
    /// ** channel_types can only be used for channel select menu components.
    channel_types: ?[]ChannelTypes,
    /// Placeholder text if nothing is selected; max 150 characters
    placeholder: ?[]const u8,
    /// List of default values for auto-populated select menu components; number of default values must be in the range defined by min_values and max_values
    /// *** default_values is only available for auto-populated select menu components, which include user (5), role (6), mentionable (7), and channel (8) components.
    default_values: ?[]DefaultValue,
    /// Minimum number of items that must be chosen (defaults to 1); min 0, max 25
    min_values: ?usize,
    /// Maximum number of items that can be chosen (defaults to 1); max 25
    max_values: ?usize,
    /// Whether select menu is disabled (defaults to false)
    disabled: ?bool,
};

pub const SelectMenu = union(MessageComponentTypes) {
    SelectMenu: SelectMenuString,
    SelectMenuUsers: SelectMenuUsers,
    SelectMenuRoles: SelectMenuRoles,
    SelectMenuUsersAndRoles: SelectMenuUsersAndRoles,
    SelectMenuChannels: SelectMenuChannels,

    pub fn jsonParse(allocator: std.mem.Allocator, src: []const u8) !@This() {
        const value = try std.json.innerParse(std.json.Value, allocator, src, .{
            .max_value_len  = 0x100,
        });

        if (!value != .object) @panic("coulnd't match against non-object type");

        switch (value.object.get("type") orelse @panic("couldn't find property `type`")) {
            .integer => |num| return switch (@as(MessageComponentTypes, @enumFromInt(num))) {
                .SelectMenu => .{ .SelectMenu = try std.json.parseFromValue(SelectMenuString, allocator, value, .{.max_value_len = 0x100})},
                .SelectMenuUsers => .{ .SelectMenuUsers = try std.json.parseFromValue(SelectMenuUsers, allocator, value, .{.max_value_len = 0x100})},
                .SelectMenuRoles => .{ .SelectMenuRoles = try std.json.parseFromValue(SelectMenuRoles, allocator, value, .{.max_value_len = 0x100})},
                .SelectMenuUsersAndRoles => .{ .SelectMenuUsersAndRoles = try std.json.parseFromValue(SelectMenuUsersAndRoles, allocator, value, .{.max_value_len = 0x100})},
                .SelectMenuChannels => .{ .SelectMenuChannels = try std.json.parseFromValue(SelectMenuChannels, allocator, value, .{.max_value_len = 0x100})},
            },
            else => @panic("got type but couldn't match against non enum member `type`"),
        }

        return try MessageComponent.json(allocator, value);
    }

    // legacy
    pub fn json(allocator: std.mem.Allocator, value: zjson.JsonType) !@This() {
        if (!value.is(.object))
            @panic("coulnd't match against non-object type");

        switch (value.object.get("type") orelse @panic("couldn't find property `type`")) {
            .number => |num| return switch (@as(MessageComponentTypes, @enumFromInt(num.integer))) {
                .SelectMenu => .{ .SelectMenu = try zjson.parseInto(SelectMenuString, allocator, value) },
                .SelectMenuUsers => .{ .SelectMenuUsers = try zjson.parseInto(SelectMenuUsers, allocator, value) },
                .SelectMenuRoles => .{ .SelectMenuRoles = try zjson.parseInto(SelectMenuRoles, allocator, value) },
                .SelectMenuUsersAndRoles => .{ .SelectMenuUsersAndRoles = try zjson.parseInto(SelectMenuUsersAndRoles, allocator, value) },
                .SelectMenuChannels => .{ .SelectMenuChannels = try zjson.parseInto(SelectMenuChannels, allocator, value) },
            },
            else => @panic("got type but couldn't match against non enum member `type`"),
        }
        unreachable;
    }
};

pub const InputTextStyles = enum(u4) {
    Short = 1,
    Paragraph,
};

pub const InputText = struct {
    /// 4 for a text input
    type: MessageComponentTypes,
    /// Developer-defined identifier for the input; max 100 characters
    custom_id: []const u8,
    /// The Text Input Style
    style: InputTextStyles,
    /// Label for this component; max 45 characters
    label: []const u8,
    /// Minimum input length for a text input; min 0, max 4000
    min_length: ?usize,
    /// Maximum input length for a text input; min 1, max 4000
    max_length: ?usize,
    /// Whether this component is required to be filled (defaults to true)
    required: ?bool,
    /// Pre-filled value for this component; max 4000 characters
    value: ?[]const u8,
    /// Custom placeholder text if the input is empty; max 100 characters
    placeholder: ?[]const u8,
};

pub const MessageComponent = union(MessageComponentTypes) {
    ActionRow: []MessageComponent,
    Button: Button,
    SelectMenu: SelectMenuString,
    InputText: InputText,
    SelectMenuUsers: SelectMenuUsers,
    SelectMenuRoles: SelectMenuRoles,
    SelectMenuUsersAndRoles: SelectMenuUsersAndRoles,
    SelectMenuChannels: SelectMenuChannels,

    pub fn json(allocator: std.mem.Allocator, value: zjson.JsonType) !@This() {
        if (!value.is(.object))
            @panic("coulnd't match against non-object type");

        switch (value.object.get("type") orelse @panic("couldn't find property `type`")) {
            .number => |num| return switch (@as(MessageComponentTypes, @enumFromInt(num.integer))) {
                .ActionRow => .{ .ActionRow = try zjson.parseInto([]MessageComponent, allocator, value) },
                .Button => .{ .Button = try zjson.parseInto(Button, allocator, value) },
                .SelectMenu => .{ .SelectMenu = try zjson.parseInto(SelectMenuString, allocator, value) },
                .InputText => .{ .InputText = try zjson.parseInto(InputText, allocator, value) },
                .SelectMenuUsers => .{ .SelectMenuUsers = try zjson.parseInto(SelectMenuUsers, allocator, value) },
                .SelectMenuRoles => .{ .SelectMenuRoles = try zjson.parseInto(SelectMenuRoles, allocator, value) },
                .SelectMenuUsersAndRoles => .{ .SelectMenuUsersAndRoles = try zjson.parseInto(SelectMenuUsersAndRoles, allocator, value) },
                .SelectMenuChannels => .{ .SelectMenuChannels = try zjson.parseInto(SelectMenuChannels, allocator, value) },
            },
            else => @panic("got type but couldn't match against non enum member `type`"),
        }
    }
};
