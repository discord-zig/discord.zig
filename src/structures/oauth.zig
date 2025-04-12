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

    const OAuth2Scope = @import("shared.zig").OAuth2Scope;
    const Guild = @import("guild.zig").Guild;
    const IncomingWebhook = @import("webhook.zig").IncomingWebhook;

    pub const TokenExchangeAuthorizationCode = struct {
        grant_type: []const u8, //"authorization_code",
        /// The code for the token exchange
        code: []const u8,
        /// The redirect_uri associated with this authorization
        redirect_uri: []const u8,
    };

    /// https://discord.com/developers/docs/topics/oauth2#client-credentials-grant
    pub const TokenExchangeRefreshToken = struct {
        grant_type: "refresh_token",
        /// the user's refresh token
        refresh_token: []const u8,
    };

    /// https://discord.com/developers/docs/topics/oauth2#client-credentials-grant
    pub const TokenExchangeClientCredentials = struct {
        grant_type: "client_credentials",
        /// The scope(s) for the access token
        scope: []OAuth2Scope,
    };

    pub const AccessTokenResponse = struct {
        /// The access token of the user
        access_token: []const u8,
        /// The type of token
        token_type: []const u8,
        /// The isize of seconds after that the access token is expired
        expires_in: isize,
        ///
        /// The refresh token to refresh the access token
        ///
        /// @remarks
        /// When the token exchange is a client credentials type grant this value is not defined.
        ///
        refresh_token: []const u8,
        /// The scopes for the access token
        scope: []const u8,
        /// The webhook the user created for the application. Requires the `webhook.incoming` scope
        webhook: ?IncomingWebhook = null,
        /// The guild the bot has been added. Requires the `bot` scope
        guild: ?Guild = null,
};
