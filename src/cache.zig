const std = @import("std");

// by default this caches everything
// therefore we'll allow custom cache tables
pub const CacheTables = struct {
    const Snowflake = @import("./structures/snowflake.zig").Snowflake;
    const Types = @import("./structures/types.zig");

    const StoredUser = @import("./config.zig").StoredUser;
    const StoredGuild = @import("./config.zig").StoredGuild;
    const StoredChannel = @import("./config.zig").StoredChannel;
    const StoredEmoji = @import("./config.zig").StoredEmoji;
    const StoredMessage = @import("./config.zig").StoredMessage;
    const StoredRole = @import("./config.zig").StoredRole;
    const StoredSticker = @import("./config.zig").StoredSticker;
    const StoredReaction = @import("./config.zig").StoredReaction;
    const StoredMember = @import("./config.zig").StoredMember;

    users: CacheLike(Snowflake, StoredUser),
    guilds: CacheLike(Snowflake, StoredGuild),
    channels: CacheLike(Snowflake, StoredChannel),
    emojis: CacheLike(Snowflake, StoredEmoji),
    messages: CacheLike(Snowflake, StoredMessage),
    roles: CacheLike(Snowflake, StoredRole),
    stickers: CacheLike(Snowflake, StoredSticker),
    reactions: CacheLike(Snowflake, StoredReaction),
    members: CacheLike(Snowflake, StoredMember),
    threads: CacheLike(Snowflake, StoredChannel),

    /// you can customize with your own cache
    pub fn defaults(allocator: std.mem.Allocator) CacheTables {
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

pub fn CacheLike(comptime K: type, comptime V: type) type {
    return struct {
        ptr: *anyopaque,
        putFn: *const fn(*anyopaque, K, V) anyerror!void,
        getFn: *const fn(*anyopaque, K) ?V,
        removeFn: *const fn(*anyopaque, K) void,
        containsFn: *const fn(*anyopaque, K) bool,
        countFn: *const fn(*anyopaque) usize,

        pub fn put(self: CacheLike(K, V), key: K, value: V) !void {
            self.putFn(self.ptr, key, value);
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

// make a cache that uses a hash map
// must have putFn, getFn, removeFn, etc
// must have a cache() function to return the interface

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
