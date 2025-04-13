const BitwisePermissionFlags = @import("../structures/shared.zig").BitwisePermissionFlags;

pub const Permissions = struct {
    bitfield: BitwisePermissionFlags = .{},

    pub fn all() BitwisePermissionFlags {
        var bits: @Vector(u64, u1) = @bitCast(BitwisePermissionFlags{});

        bits = @splat(1);

        return BitwisePermissionFlags.fromRaw(@bitCast(bits));
    }

    pub fn init(bitfield: anytype) Permissions {
        return Permissions{ .bitfield = @bitCast(bitfield) };
    }

    pub fn has(self: Permissions, bit: u1) bool {
        return (self.bitfield & bit) == bit;
    }

    pub fn missing(self: Permissions, bit: u1) bool {
        return (self.bitfield & bit) == 0;
    }

    pub fn equals(self: Permissions, other: anytype) bool {
        return self.bitfield == Permissions.init(other).bitfield;
    }

    pub fn add(self: Permissions, bit: u1) void {
        self.bitfield |= bit;
    }

    pub fn remove(self: Permissions, bit: u1) void {
        self.bitfield &= ~bit;
    }

    pub fn has2(self: Permissions, bit: u1) bool {
        const administrator = BitwisePermissionFlags{ .ADMINISTRATOR = true };
        return self.has(bit) or (self.bitfield & administrator) == administrator;
    }

    pub fn toRaw(self: Permissions) u64 {
        return @bitCast(self.bitfield);
    }

    pub fn fromRaw(raw: u64) Permissions {
        return Permissions{ .bitfield = @bitCast(raw) };
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
