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

/// an error ought to be matched by `code` for providing the end user with sensible errors
pub const DiscordErrorPayload = struct {
    /// cryptic error code, eg: `MISSING_PERMISSIONS`
    code: []const u8,
    /// human readable error message
    message: []const u8,
};

pub const DiscordError = struct {
    code: usize,
    message: []const u8,
    errors: ?struct { _errors: []DiscordErrorPayload },
};

pub fn Result(comptime T: type) type {
    return @import("json-helper.zig").OwnedEither(DiscordError, T);
}
