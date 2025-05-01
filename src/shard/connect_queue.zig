const std = @import("std");
const mem = std.mem;

/// inspired from:
/// https://github.com/tiramisulabs/seyfert/blob/main/src/websocket/structures/timeout.ts
pub fn ConnectQueue(comptime T: type) type {
    return struct {
        pub const RequestWithShard = struct {
            callback: *const fn (self: *RequestWithShard) anyerror!void,
            shard: T,
        };

        // ignore this function
        // so it becomes a regular dequeue
        fn eq(_: void, _: RequestWithShard, _: RequestWithShard) std.math.Order {
            return std.math.Order.eq;
        }

        dequeue: std.PriorityDequeue(RequestWithShard, void, eq),
        allocator: mem.Allocator,
        remaining: usize,
        interval_time: u64 = 5000,
        running: bool = false,
        concurrency: usize = 1,

        pub fn init(allocator: mem.Allocator, concurrency: usize, interval_time: u64) !ConnectQueue(T) {
            return .{
                .allocator = allocator,
                .dequeue = std.PriorityDequeue(RequestWithShard, void, eq).init(allocator, {}),
                .remaining = concurrency,
                .interval_time = interval_time,
                .concurrency = concurrency,
            };
        }

        pub fn deinit(self: *ConnectQueue(T)) void {
            self.dequeue.deinit();
        }

        pub fn push(self: *ConnectQueue(T), req: RequestWithShard) !void {
            if (self.remaining == 0) {
                return self.dequeue.add(req);
            }
            self.remaining -= 1;

            if (!self.running) {
                try self.startInterval();
                self.running = true;
            }

            if (self.dequeue.count() < self.concurrency) {
                // perhaps store this?
                const ptr = try self.allocator.create(RequestWithShard);
                ptr.* = req;
                try req.callback(ptr);
                return;
            }

            return self.dequeue.add(req);
        }

        fn startInterval(self: *ConnectQueue(T)) !void {
            while (self.running) {
                std.Thread.sleep(std.time.ns_per_ms * (self.interval_time / self.concurrency));
                const req: ?RequestWithShard = self.dequeue.removeMin(); // pop front

                while (self.dequeue.count() == 0 and req == null) {}

                if (req) |r| {
                    const ptr = try self.allocator.create(RequestWithShard);
                    ptr.* = r;
                    try @call(.auto, r.callback, .{ptr});
                    return;
                }

                if (self.remaining < self.concurrency) {
                    self.remaining += 1;
                }

                if (self.dequeue.count() == 0) {
                    self.running = false;
                }
            }
        }
    };
}

