    const Snowflake = @import("snowflake.zig").Snowflake;
    const User = @import("user.zig").User;
    const StickerTypes = @import("shared.zig").StickerTypes;
    const StickerFormatTypes = @import("shared.zig").StickerFormatTypes;

    /// https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-structure
    pub const Sticker = struct {
        /// [Id of the sticker](https://discord.com/developers/docs/reference#image-formatting)
        id: Snowflake,
        /// Id of the pack the sticker is from
        pack_id: ?Snowflake = null,
        /// Name of the sticker
        name: []const u8,
        /// Description of the sticker
        description: []const u8,
        /// a unicode emoji representing the sticker's expression
        tags: []const u8,
        /// [type of sticker](https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-types)
        type: StickerTypes,
        /// [Type of sticker format](https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-format-types)
        format_type: StickerFormatTypes,
        ///  Whether or not the sticker is available
        available: ?bool = null,
        /// Id of the guild that owns this sticker
        guild_id: ?Snowflake = null,
        /// The user that uploaded the sticker
        user: ?User = null,
        /// A sticker's sort order within a pack
        sort_value: ?isize = null,
    };

    /// https://discord.com/developers/docs/resources/sticker#sticker-item-object-sticker-item-structure
    pub const StickerItem = struct {
        /// Id of the sticker
        id: Snowflake,
        /// Name of the sticker
        name: []const u8,
        /// [Type of sticker format](https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-format-types)
        format_type: StickerFormatTypes,
    };

    /// https://discord.com/developers/docs/resources/sticker#sticker-pack-object-sticker-pack-structure
    pub const StickerPack = struct {
        /// id of the sticker pack
        id: Snowflake,
        /// the stickers in the pack
        stickers: []Sticker,
        /// name of the sticker pack
        name: []const u8,
        /// id of the pack's SKU
        sku_id: Snowflake,
        /// id of a sticker in the pack which is shown as the pack's icon
        cover_sticker_id: ?Snowflake = null,
        /// description of the sticker pack
        description: []const u8,
        /// id of the sticker pack's [banner image](https://discord.com/developers/docs/reference#image-formatting)
        banner_asset_id: ?Snowflake = null,
    };

    pub const CreateModifyGuildSticker = struct {
        /// name of the sticker (2-30 characters)
        name: ?[]const u8 = null,
        /// description of the sticker (2-100 characters)
        description: ?[]const u8 = null,
        /// autocomplete/suggestion tags for the sticker (max 200 characters)
        tags: ?[]const u8 = null,
};
