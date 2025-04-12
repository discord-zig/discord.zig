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
    const SkuFlags = @import("shared.zig").SkuFlags;

    /// https://discord.com/developers/docs/monetization/entitlements#entitlement-object-entitlement-structure
    pub const Entitlement = struct {
        /// ID of the entitlement
        id: Snowflake,
        /// ID of the SKU
        sku_id: Snowflake,
        /// ID of the user that is granted access to the entitlement's sku
        user_id: ?Snowflake = null,
        /// ID of the guild that is granted access to the entitlement's sku
        guild_id: ?Snowflake = null,
        /// ID of the parent application
        application_id: Snowflake,
        /// Type of entitlement
        type: EntitlementType,
        /// Entitlement was deleted
        deleted: bool,
        /// Start date at which the entitlement is valid. Not present when using test entitlements
        starts_at: ?[]const u8 = null,
        /// Date at which the entitlement is no longer valid. Not present when using test entitlements
        ends_at: ?[]const u8 = null,
        /// For consumable items, whether or not the entitlement has been consumed
        consumed: ?bool = null,
};

/// https://discord.com/developers/docs/monetization/entitlements#entitlement-object-entitlement-types
pub const EntitlementType = enum(u4) {
    /// Entitlement was purchased by user
    Purchase = 1,
    ///Entitlement for  Nitro subscription
    PremiumSubscription = 2,
    /// Entitlement was gifted by developer
    DeveloperGift = 3,
    /// Entitlement was purchased by a dev in application test mode
    TestModePurchase = 4,
    /// Entitlement was granted when the SKU was free
    FreePurchase = 5,
    /// Entitlement was gifted by another user
    UserGift = 6,
    /// Entitlement was claimed by user for free as a Nitro Subscriber
    PremiumPurchase = 7,
    /// Entitlement was purchased as an app subscription
    ApplicationSubscription = 8,
};

/// https://discord.com/developers/docs/monetization/skus#sku-object-sku-structure
pub const Sku = struct {
    /// ID of SKU
    id: Snowflake,
    /// Type of SKU
    type: SkuType,
    /// ID of the parent application
    application_id: Snowflake,
    /// Customer-facing name of your premium offering
    name: []const u8,
    /// System-generated URL slug based on the SKU's name
    slug: []const u8,
    /// SKU flags combined as a bitfield
    flags: SkuFlags,
};

/// https://discord.com/developers/docs/monetization/skus#sku-object-sku-types
pub const SkuType = enum(u4) {
    /// Durable one-time purchase
    Durable = 2,
    /// Consumable one-time purchase
    Consumable = 3,
    /// Represents a recurring subscription
    Subscription = 5,
    /// System-generated group for each SUBSCRIPTION SKU created
    SubscriptionGroup = 6,
};

pub const CreateTestEntitlement = struct {
    /// ID of the SKU to grant the entitlement to
    sku_id: []const u8,
    /// ID of the guild or user to grant the entitlement top
    owner_id: []const u8,
    /// 1 for a guild subscription, 2 for a user subscription
    owner_type: enum(u4) {
        guild_subscription = 1,
        user_subscription = 2,
    },
};
