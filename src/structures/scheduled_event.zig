const Snowflake = @import("snowflake.zig").Snowflake;
const ScheduledEventPrivacyLevel = @import("shared.zig").ScheduledEventPrivacyLevel;
const ScheduledEventStatus = @import("shared.zig").ScheduledEventStatus;
const ScheduledEventEntityType = @import("shared.zig").ScheduledEventEntityType;
const User = @import("user.zig").User;

pub const ScheduledEvent = struct {
    /// the id of the scheduled event
    id: Snowflake,
    /// the guild id which the scheduled event belongs to
    guild_id: Snowflake,
    /// the channel id in which the scheduled event will be hosted if specified
    channel_id: ?Snowflake,
    /// the id of the user that created the scheduled event
    creator_id: ?Snowflake,
    /// the name of the scheduled event
    name: []const u8,
    /// the description of the scheduled event
    description: ?[]const u8,
    /// the time the scheduled event will start
    scheduled_start_time: []const u8,
    /// the time the scheduled event will end if it does end.
    scheduled_end_time: ?[]const u8,
    /// the privacy level of the scheduled event
    privacy_level: ScheduledEventPrivacyLevel,
    /// the status of the scheduled event
    status: ScheduledEventStatus,
    /// the type of hosting entity associated with a scheduled event
    entity_type: ScheduledEventEntityType,
    /// any additional id of the hosting entity associated with event
    entity_id: ?Snowflake,
    /// the entity metadata for the scheduled event
    entity_metadata: ?ScheduledEventEntityMetadata,
    /// the user that created the scheduled event
    creator: ?User,
    /// the isize of users subscribed to the scheduled event
    user_count: ?isize,
    /// the cover image hash of the scheduled event
    image: ?[]const u8,
    /// the definition for how often this event should recur
    recurrence_rule: ?ScheduledEventRecurrenceRule,
};

pub const ScheduledEventEntityMetadata = struct {
    /// location of the event
    location: ?[]const u8,
};

pub const ScheduledEventRecurrenceRule = struct {
    /// Starting time of the recurrence interval
    start: []const u8,
    /// Ending time of the recurrence interval
    end: ?[]const u8,
    /// How often the event occurs
    frequency: ScheduledEventRecurrenceRuleFrequency,
    /// The spacing between the events, defined by `frequency`. For example, `frequency` of `Weekly` and an `interval` of `2` would be "every-other week"
    interval: isize,
    /// Set of specific days within a week for the event to recur on
    by_weekday: ?[]ScheduledEventRecurrenceRuleWeekday,
    /// List of specific days within a specific week (1-5) to recur on
    by_n_weekday: ?[]ScheduledEventRecurrenceRuleNWeekday,
    /// Set of specific months to recur on
    by_month: ?[]ScheduledEventRecurrenceRuleMonth,
    /// Set of specific dates within a month to recur on
    by_month_day: ?[]isize,
    /// Set of days within a year to recur on (1-364)
    by_year_day: ?[]isize,
    /// The total amount of times that the event is allowed to recur before stopping
    count: ?isize,
};

pub const ScheduledEventRecurrenceRuleFrequency = enum {
    Yearly,
    Monthly,
    Weekly,
    Daily,
};

pub const ScheduledEventRecurrenceRuleWeekday = enum {
    Monday,
    Tuesday,
    Wednesday,
    Thursday,
    Friday,
    Saturday,
    Sunday,
};

pub const ScheduledEventRecurrenceRuleNWeekday = struct {
    /// The week to reoccur on. 1 - 5
    n: isize,
    /// The day within the week to reoccur on
    day: ScheduledEventRecurrenceRuleWeekday,
};

pub const ScheduledEventRecurrenceRuleMonth = enum(u4) {
    January = 1,
    February,
    March,
    April,
    May,
    June,
    July,
    August,
    September,
    October,
    November,
    December,
};