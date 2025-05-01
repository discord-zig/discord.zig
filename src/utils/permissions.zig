const BitwisePermissionFlags = @import("../structures/shared.zig").BitwisePermissionFlags;
const IntegerBitSet = @import("std").StaticBitSet(usize);

pub const Permissions = struct {
    bitset: IntegerBitSet = .initEmpty(),
    const bitfield = BitwisePermissionFlags{};

    pub const none = Permissions{};

    pub fn all() Permissions {
        return .{ .bitset = .initFull() };
    }

    pub fn has(self: Permissions, permission: BitwisePermissionFlags) bool {
        return self.bitset.isSet(@intCast(permission));
    }

    pub fn missing(self: Permissions, permission: BitwisePermissionFlags) bool {
        return !self.bitset.isSet(@intCast(permission));
    }

    pub fn isAdmin(self: Permissions) bool {
        return self.bitset.isSet(@intCast(BitwisePermissionFlags.ADMIN));
    }

    pub fn set(self: Permissions, permission: BitwisePermissionFlags) void {
        self.bitset.set(@intCast(permission));
    }

    pub fn eql(self: Permissions, other: Permissions) bool {
        return self.bitset.eql(other.bitset);
    }

    pub fn any(self: Permissions, other: Permissions) bool {
        return self.bitset.supersetOf(other.bitset);
    }

    pub fn toRaw(self: Permissions) u64 {
        return @intCast(self.bitset.mask);
    }

    pub fn fromRaw(raw: u64) Permissions {
        return .{ .bitset = .{ .mask = raw } };
    }

    /// std.json stringify
    pub fn jsonStringify(permissions: Permissions, writer: anytype) !void {
        try writer.print("<Permissions 0x{x}>", .{permissions.toRaw()});
    }
};

const testing = @import("std").testing;

test {
    const all_permissions = Permissions.all();

    // 2^40 - 1 = 1099511627775
    const ALL: u64 = 1099511627775;

    testing.expectEqual(all_permissions.toRaw(), ALL);
}

test "is admin and set works" {
    var permissions = Permissions.none;
    permissions.set(Permissions.bitfield.ADMINISTRATOR);
    testing.expect(permissions.isAdmin());
}

test "eql works" {
    var permissions1 = Permissions.none;
    var permissions2 = Permissions.none;
    permissions1.set(Permissions.bitfield.ADMINISTRATOR);
    permissions2.set(Permissions.bitfield.ADMINISTRATOR);
    testing.expect(permissions1.eql(permissions2));
}

test "has permission" {
    var permissions = Permissions.none;
    permissions.set(Permissions.bitfield.ADMINISTRATOR);
    testing.expect(permissions.has(Permissions.bitfield.ADMINISTRATOR));
    testing.expect(!permissions.has(Permissions.bitfield.MANAGE_ROLES));
}

test "missing permission" {
    var permissions = Permissions.none;
    permissions.set(Permissions.bitfield.ADMINISTRATOR);
    testing.expect(!permissions.missing(Permissions.bitfield.ADMINISTRATOR));
    testing.expect(permissions.missing(Permissions.bitfield.MANAGE_ROLES));
}

test "missing multiple permissions" {
    var permissions1 = Permissions.none;
    permissions1.set(Permissions.bitfield.KICK_MEMBERS); // only has kick members

    var permissions2 = Permissions.none; // to check
    permissions2.set(Permissions.bitfield.BAN_MEMBERS);
    permissions2.set(Permissions.bitfield.KICK_MEMBERS);

    // has both permissions
    testing.expect(permissions1.missing(permissions2));
}

test "any permissions" {
    var permissions1 = Permissions.none;
    var permissions2 = Permissions.none;
    permissions1.set(Permissions.bitfield.ADMINISTRATOR);
    permissions2.set(Permissions.bitfield.MANAGE_GUILD);

    testing.expect(!permissions1.any(permissions2));

    permissions2.set(Permissions.bitfield.MANAGE_GUILD);

    testing.expect(permissions1.any(permissions2));
}
