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

    const EmbedTypes = @import("shared.zig").EmbedTypes;

    /// https://discord.com/developers/docs/resources/channel#embed-object
    pub const Embed = struct {
        /// Title of embed
        title: ?[]const u8 = null,
        /// Type of embed (always "rich" for webhook embeds)
        type: ?EmbedTypes = null,
        /// Description of embed
        description: ?[]const u8 = null,
        /// Url of embed
        url: ?[]const u8 = null,
        /// Color code of the embed
        color: ?isize = null,
        /// Timestamp of embed content
        timestamp: ?[]const u8 = null,
        /// Footer information
        footer: ?EmbedFooter = null,
        /// Image information
        image: ?EmbedImage = null,
        /// Thumbnail information
        thumbnail: ?EmbedThumbnail = null,
        /// Video information
        video: ?EmbedVideo = null,
        /// Provider information
        provider: ?EmbedProvider = null,
        /// Author information
        author: ?EmbedAuthor = null,
        /// Fields information
        fields: ?[]EmbedField = null,
    };

    /// https://discord.com/developers/docs/resources/channel#embed-object-embed-author-structure
    pub const EmbedAuthor = struct {
        /// Name of author
        name: []const u8,
        /// Url of author
        url: ?[]const u8 = null,
        /// Url of author icon (only supports http(s) and attachments)
        icon_url: ?[]const u8 = null,
        /// A proxied url of author icon
        proxy_icon_url: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/channel#embed-object-embed-field-structure
    pub const EmbedField = struct {
        /// Name of the field
        name: []const u8,
        /// Value of the field
        value: []const u8,
        /// Whether or not this field should display inline
        @"inline"    : ?bool = null,
    };

    /// https://discord.com/developers/docs/resources/channel#embed-object-embed-footer-structure
    pub const EmbedFooter = struct {
        /// Footer text
        text: []const u8,
        /// Url of footer icon (only supports http(s) and attachments)
        icon_url: ?[]const u8 = null,
        /// A proxied url of footer icon
        proxy_icon_url: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/channel#embed-object-embed-image-structure
    pub const EmbedImage = struct {
        /// Source url of image (only supports http(s) and attachments)
        url: []const u8,
        /// A proxied url of the image
        proxy_url: ?[]const u8 = null,
        /// Height of image
        height: ?isize = null,
        /// Width of image
        width: ?isize = null,
    };

    pub const EmbedProvider = struct {
        /// Name of provider
        name: ?[]const u8 = null,
        /// Url of provider
        url: ?[]const u8 = null,
    };

    /// https://discord.com/developers/docs/resources/channel#embed-object-embed-thumbnail-structure
    pub const EmbedThumbnail = struct {
        /// Source url of thumbnail (only supports http(s) and attachments)
        url: []const u8,
        /// A proxied url of the thumbnail
        proxy_url: ?[]const u8 = null,
        /// Height of thumbnail
        height: ?isize = null,
        /// Width of thumbnail
        width: ?isize = null,
    };

    /// https://discord.com/developers/docs/resources/channel#embed-object-embed-video-structure
    pub const EmbedVideo = struct {
        /// Source url of video
        url: ?[]const u8 = null,
        /// A proxied url of the video
        proxy_url: ?[]const u8 = null,
        /// Height of video
        height: ?isize = null,
        /// Width of video
        width: ?isize = null,
};
