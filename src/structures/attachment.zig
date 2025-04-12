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
    const AttachmentFlags = @import("shared.zig").AttachmentFlags;

    /// https://discord.com/developers/docs/resources/channel#attachment-object
    pub const Attachment = struct {
        /// Name of file attached
        filename: []const u8,
        /// The title of the file
        title: ?[]const u8 = null,
        /// The attachment's [media type](https://en.wikipedia.org/wiki/Media_type)
        content_type: ?[]const u8 = null,
        /// Size of file in bytes
        size: isize,
        /// Source url of file
        url: []const u8,
        /// A proxied url of file
        proxy_url: []const u8,
        /// Attachment id
        id: Snowflake,
        /// description for the file (max 1024 characters)
        description: ?[]const u8 = null,
        /// Height of file (if image)
        height: ?isize = null,
        /// Width of file (if image)
        width: ?isize = null,
        /// whether this attachment is ephemeral. Ephemeral attachments will automatically be removed after a set period of time. Ephemeral attachments on messages are guaranteed to be available as long as the message itself exists.
        ephemeral: ?bool = null,
        /// The duration of the audio file for a voice message
        duration_secs: ?isize = null,
        /// A base64 encoded bytearray representing a sampled waveform for a voice message
        waveform: ?[]const u8 = null,
        /// Attachment flags combined as a bitfield
        flags: ?AttachmentFlags = null,
};
