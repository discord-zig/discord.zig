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

    /// https://discord.com/developers/docs/resources/emoji#emoji-object-emoji-structure
    pub const Emoji = struct {
        /// Emoji name (can only be null in reaction emoji objects)
        name: ?[]const u8 = null,
        /// Emoji id
        id: ?Snowflake = null,
        /// Roles allowed to use this emoji
        roles: ?[][]const u8 = null,
        /// User that created this emoji
        user: ?User = null,
        /// Whether this emoji must be wrapped in colons
        require_colons: ?bool = null,
        /// Whether this emoji is managed
        managed: ?bool = null,
        /// Whether this emoji is animated
        animated: ?bool = null,
        /// Whether this emoji can be used, may be false due to loss of Server Boosts
        available: ?bool = null,
};
