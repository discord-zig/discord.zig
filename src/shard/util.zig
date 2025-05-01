pub const IdentifyProperties = struct {
    /// Operating system the shard runs on.
    os: []const u8,
    /// The "browser" where this shard is running on.
    browser: []const u8,
    /// The device on which the shard is running.
    device: []const u8,
};

pub const default_identify_properties = IdentifyProperties{
    .os = @tagName(@import("builtin").os.tag),
    .browser = "discord.zig",
    .device = "discord.zig",
};

/// https://discord.com/developers/docs/topics/gateway#get-gateway
pub const GatewayInfo = struct {
    /// The WSS URL that can be used for connecting to the gateway
    url: []const u8,
};

/// https://discord.com/developers/docs/events/gateway#session-start-limit-object
pub const GatewaySessionStartLimit = struct {
    /// Total number of session starts the current user is allowed
    total: u32,
    /// Remaining number of session starts the current user is allowed
    remaining: u32,
    /// Number of milliseconds after which the limit resets
    reset_after: u32,
    /// Number of identify requests allowed per 5 seconds
    max_concurrency: u32,
};

/// https://discord.com/developers/docs/topics/gateway#get-gateway-bot
pub const GatewayBotInfo = struct {
    url: []const u8,
    /// The recommended number of shards to use when connecting
    ///
    /// See https://discord.com/developers/docs/topics/gateway#sharding
    shards: u32,
    /// Information on the current session start limit
    ///
    /// See https://discord.com/developers/docs/topics/gateway#session-start-limit-object
    session_start_limit: ?GatewaySessionStartLimit,
};

pub const ShardDetails = struct {
    /// Bot token which is used to connect to Discord */
    token: []const u8,
    /// The URL of the gateway which should be connected to.
    url: []const u8 = "wss://gateway.discord.gg",
    /// The gateway version which should be used.
    version: ?usize = 10,
    /// The calculated intent value of the events which the shard should receive.
    intents: @import("./intents.zig").Intents,
    /// Identify properties to use
    properties: IdentifyProperties = default_identify_properties,
};

