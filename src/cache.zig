const std = @import("std");

/// defaults are to be overridden by the end user
/// otherwise, simply do TableTemplate{}
/// this is a template for the cache tables
pub const TableTemplate = struct {
    comptime User: type = @import("./config.zig").StoredUser,
    comptime Guild: type = @import("./config.zig").StoredGuild,
    comptime Channel: type = @import("./config.zig").StoredChannel,
    comptime Emoji: type = @import("./config.zig").StoredEmoji,
    comptime Message: type = @import("./config.zig").StoredMessage,
    comptime Role: type = @import("./config.zig").StoredRole,
    comptime Sticker: type = @import("./config.zig").StoredSticker,
    comptime Reaction: type = @import("./config.zig").StoredReaction,
    comptime Member: type = @import("./config.zig").StoredMember,
    comptime Thread: type = @import("./config.zig").StoredChannel,
};

// by default this caches everything
// therefore we'll allow custom cache tables
pub fn CacheTables(comptime Table: TableTemplate) type {
    return struct {
        const Snowflake = @import("./structures/snowflake.zig").Snowflake;

        const StoredUser: type = Table.User;
        const StoredGuild: type = Table.Guild;
        const StoredChannel: type = Table.Channel;
        const StoredEmoji: type = Table.Emoji;
        const StoredMessage: type = Table.Message;
        const StoredRole: type = Table.Role;
        const StoredSticker: type = Table.Sticker;
        const StoredReaction: type = Table.Reaction;
        const StoredMember: type = Table.Member;
        const StoredThread: type = Table.Thread;

        users: CacheLike(Snowflake, StoredUser),
        guilds: CacheLike(Snowflake, StoredGuild),
        channels: CacheLike(Snowflake, StoredChannel),
        emojis: CacheLike(Snowflake, StoredEmoji),
        messages: CacheLike(Snowflake, StoredMessage),
        roles: CacheLike(Snowflake, StoredRole),
        stickers: CacheLike(Snowflake, StoredSticker),
        reactions: CacheLike(Snowflake, StoredReaction),
        members: CacheLike(Snowflake, StoredMember),
        threads: CacheLike(Snowflake, StoredThread),

        /// you can customize with your own cache
        pub fn defaults(allocator: std.mem.Allocator) CacheTables(Table) {
            var users = DefaultCache(Snowflake, StoredUser).init(allocator);
            var guilds = DefaultCache(Snowflake, StoredGuild).init(allocator);
            var channels = DefaultCache(Snowflake, StoredChannel).init(allocator);
            var emojis = DefaultCache(Snowflake, StoredEmoji).init(allocator);
            var messages = DefaultCache(Snowflake, StoredMessage).init(allocator);
            var roles = DefaultCache(Snowflake, StoredRole).init(allocator);
            var stickers = DefaultCache(Snowflake, StoredSticker).init(allocator);
            var reactions = DefaultCache(Snowflake, StoredReaction).init(allocator);
            var members = DefaultCache(Snowflake, StoredMember).init(allocator);
            var threads = DefaultCache(Snowflake, StoredChannel).init(allocator);

            return .{
                .users = users.cache(),
                .guilds = guilds.cache(),
                .channels = channels.cache(),
                .emojis = emojis.cache(),
                .messages = messages.cache(),
                .roles = roles.cache(),
                .stickers = stickers.cache(),
                .reactions = reactions.cache(),
                .members = members.cache(),
                .threads = threads.cache(),
            };
        }
    };
}

/// this is an extensible cache, you may implement your own
/// I recommend "zigache" to be used
pub fn CacheLike(comptime K: type, comptime V: type) type {
    return struct {
        ptr: *anyopaque,
        putFn: *const fn(*anyopaque, K, V) anyerror!void,
        getFn: *const fn(*anyopaque, K) ?V,
        removeFn: *const fn(*anyopaque, K) void,
        containsFn: *const fn(*anyopaque, K) bool,
        countFn: *const fn(*anyopaque) usize,

        pub fn put(self: CacheLike(K, V), key: K, value: V) !void {
            return self.putFn(self.ptr, key, value);
        }

        pub fn get(self: CacheLike(K, V), key: K) ?V {
            return self.getFn(self.ptr, key);
        }

        pub fn remove(self: CacheLike(K, V), key: K) void {
            self.removeFn(self.ptr, key);
        }

        pub fn contains(self: CacheLike(K, V), key: K) bool {
            return self.containsFn(self.ptr, key);
        }

        pub fn count(self: CacheLike(K, V)) usize {
            return self.countFn(self.ptr);
        }

        pub fn init(ptr: *const anyopaque) CacheLike(K, V) {
            const T = @TypeOf(ptr);
            const ptr_info = @typeInfo(T);

            const gen = struct {
                // we don't care about order
                map: std.AutoHashMap(K, V),
                allocator: *std.mem.Allocator,

                pub fn put(pointer: *anyopaque, key: K, value: V) anyerror!void {
                    const self: T = @ptrCast(@alignCast(pointer));
                    return ptr_info.pointer.child.put(self, key, value);
                }

                pub fn get(pointer: *anyopaque, key: K) ?V {
                    const self: T = @ptrCast(@alignCast(pointer));
                    return ptr_info.pointer.child.get(self, key);
                }

                pub fn remove(pointer: *anyopaque, key: K) void {
                    const self: T = @ptrCast(@alignCast(pointer));
                    return ptr_info.pointer.child.remove(self, key);
                }

                pub fn contains(pointer: *anyopaque, key: K) bool {
                    const self: T = @ptrCast(@alignCast(pointer));
                    return ptr_info.pointer.child.contains(self, key);
                }

                pub fn count(pointer: *anyopaque) usize {
                    const self: T = @ptrCast(@alignCast(pointer));
                    return ptr_info.pointer.child.count(self);
                }
            };

            return .{
                .ptr = ptr,
                .putFn = gen.put,
                .getFn = gen.get,
                .removeFn = gen.remove,
                .containsFn = gen.contains,
                .countFn = gen.count,
            };
        }
    };
}

pub fn DefaultCache(comptime K: type, comptime V: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        map: std.AutoHashMap(K, V),

        pub fn init(allocator: std.mem.Allocator) DefaultCache(K, V) {
                return .{ .allocator = allocator, .map = .init(allocator) };
        }

        pub fn cache(self: *Self) CacheLike(K, V) {
            return .{
                .ptr = self,
                .putFn = put,
                .getFn = get,
                .removeFn = remove,
                .containsFn = contains,
                .countFn = count,
            };
        }

        pub fn put(ptr: *anyopaque, key: K, value: V) !void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            return self.map.put(key, value);
        }

        pub fn get(ptr: *anyopaque, key: K) ?V {
            const self: *Self = @ptrCast(@alignCast(ptr));
            return self.map.get(key);
        }

        pub fn remove(ptr: *anyopaque, key: K) void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            _ = self.map.remove(key);
        }

        pub fn contains(ptr: *anyopaque, key: K) bool {
            const self: *Self = @ptrCast(@alignCast(ptr));
            return self.map.contains(key);
        }

        pub fn count(ptr: *anyopaque) usize {
            const self: *Self = @ptrCast(@alignCast(ptr));
            return self.map.count();
        }
    };
}
