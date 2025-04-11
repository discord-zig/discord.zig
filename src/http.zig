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

const std = @import("std");
const mem = std.mem;
const http = std.http;
const json = std.json;
const json_helpers = @import("json-helper.zig");

pub const Result = @import("errors.zig").Result;
pub const DiscordError = @import("errors.zig").DiscordError;

pub const BASE_URL = "https://discord.com/api/v10";

// zig fmt: off
pub const MakeRequestError = (
       std.fmt.BufPrintError
    || http.Client.ConnectTcpError
    || http.Client.Request.WaitError
    || http.Client.Request.FinishError
    || http.Client.Request.Writer.Error
    || http.Client.Request.Reader.Error
    || std.Uri.ResolveInPlaceError
    || error{StreamTooLong}
);
// zig fmt: on

pub const FetchReq = struct {
    allocator: mem.Allocator,
    token: []const u8,
    client: http.Client,
    body: std.ArrayList(u8),
    /// internal
    extra_headers: std.ArrayList(http.Header),
    query_params: std.StringArrayHashMap([]const u8),

    pub fn init(allocator: mem.Allocator, token: []const u8) FetchReq {
        const client = http.Client{ .allocator = allocator };
        return FetchReq{
            .allocator = allocator,
            .client = client,
            .token = token,
            .body = std.ArrayList(u8).init(allocator),
            .extra_headers = std.ArrayList(http.Header).init(allocator),
            .query_params = std.StringArrayHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *FetchReq) void {
        self.client.deinit();
        self.body.deinit();
    }

    pub fn addHeader(self: *FetchReq, name: []const u8, value: ?[]const u8) !void {
        if (value) |some|
            try self.extra_headers.append(http.Header{ .name = name, .value = some });
    }

    pub fn addQueryParam(self: *FetchReq, name: []const u8, value: anytype) !void {
        if (value == null)
            return;
        var buf: [256]u8 = undefined;
        try self.query_params.put(name, try std.fmt.bufPrint(&buf, "{any}", .{value}));
    }

    fn formatQueryParams(self: *FetchReq) ![]const u8 {
        var query = std.ArrayListUnmanaged(u8){};
        const writer = query.writer(self.allocator);

        if (self.query_params.count() == 0)
            return "";

        _ = try writer.write("?");
        var it = self.query_params.iterator();
        while (it.next()) |kv| {
            _ = try writer.write(kv.key_ptr.*);
            _ = try writer.write("=");
            _ = try writer.write(kv.value_ptr.*);
            if (it.next()) |_| {
                try writer.writeByte('&');
                continue;
            }
        }

        return query.toOwnedSlice(self.allocator);
    }

    pub fn get(self: *FetchReq, comptime T: type, path: []const u8) !Result(T) {
        const result = try self.makeRequest(.GET, path, null);
        if (result.status != .ok)
            return try json_helpers.parseLeft(DiscordError, T, self.allocator, try self.body.toOwnedSlice());

        const output = try json_helpers.parseRight(DiscordError, T, self.allocator, try self.body.toOwnedSlice());
        return output;
    }

    pub fn delete(self: *FetchReq, path: []const u8) !Result(void) {
        const result = try self.makeRequest(.DELETE, path, null);
        if (result.status != .no_content)
            return try json_helpers.tryParse(DiscordError, void, self.allocator, try self.body.toOwnedSlice());

        return .ok({});
    }

    pub fn patch(self: *FetchReq, comptime T: type, path: []const u8, object: anytype) !Result(T) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.PATCH, path, try string.toOwnedSlice());

        if (result.status != .ok)
            return try json_helpers.parseLeft(DiscordError, T, self.allocator, try self.body.toOwnedSlice());

        return try json_helpers.parseRight(DiscordError, T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn patch2(self: *FetchReq, path: []const u8, object: anytype) !void {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.PATCH, path, try string.toOwnedSlice());

        if (result.status != .no_content)
            return try json_helpers.parseLeft(DiscordError, void, self.allocator, try self.body.toOwnedSlice());

        return .ok({});
    }

    pub fn put(self: *FetchReq, comptime T: type, path: []const u8, object: anytype) !Result(T) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.PUT, path, try string.toOwnedSlice());

        if (result.status != .ok)
            return try json_helpers.parseLeft(DiscordError, T, self.allocator, try self.body.toOwnedSlice());

        return try json_helpers.parseRight(DiscordError, T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn put2(self: *FetchReq, comptime T: type, path: []const u8, object: anytype) !Result(T) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.PUT, path, try string.toOwnedSlice());

        if (result.status == .no_content)
            return try json_helpers.parseLeft(DiscordError, T, self.allocator, try self.body.toOwnedSlice());

        return try json_helpers.parseRight(DiscordError, T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn put3(self: *FetchReq, path: []const u8) !Result(void) {
        const result = try self.makeRequest(.PUT, path, null);

        if (result.status != .no_content)
            return try json_helpers.parseLeft(DiscordError, void, self.allocator, try self.body.toOwnedSlice());

        return .ok({});
    }

    pub fn put4(self: *FetchReq, comptime T: type, path: []const u8) !Result(T) {
        const result = try self.makeRequest(.PUT, path, null);

        if (result.status != .ok)
            return try json_helpers.parseLeft(DiscordError, T, self.allocator, try self.body.toOwnedSlice());

        return try json_helpers.parseRight(DiscordError, T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn put5(self: *FetchReq, path: []const u8, object: anytype) !Result(void) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.PUT, path, try self.body.toOwnedSlice());

        if (result.status != .no_content)
            return try json_helpers.parseLeft(DiscordError, void, self.allocator, try self.body.toOwnedSlice());

        return .ok({});
    }

    pub fn post(self: *FetchReq, comptime T: type, path: []const u8, object: anytype) !Result(T) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.POST, path, try string.toOwnedSlice());

        if (result.status != .ok)
            return try json_helpers.parseLeft(DiscordError, T, self.allocator, try self.body.toOwnedSlice());

        return try json_helpers.parseRight(DiscordError, T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn post2(self: *FetchReq, comptime T: type, path: []const u8) !Result(T) {
        const result = try self.makeRequest(.POST, path, null);

        if (result.status != .ok)
            return try json_helpers.parseLeft(DiscordError, T, self.allocator, try self.body.toOwnedSlice());

        return try json_helpers.parseRight(DiscordError, T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn post3(
        self: *FetchReq,
        comptime T: type,
        path: []const u8,
        object: anytype,
        files: []const FileData,
    ) !Result(T) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequestWithFiles(.POST, path, try string.toOwnedSlice(), files);

        if (result.status != .ok)
            return try json_helpers.parseLeft(DiscordError, T, self.allocator, try self.body.toOwnedSlice());

        return try json_helpers.parseRight(DiscordError, T, self.allocator, try self.body.toOwnedSlice());
    }

    pub fn post4(self: *FetchReq, path: []const u8, object: anytype) !Result(void) {
        var buf: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buf);
        var string = std.ArrayList(u8).init(fba.allocator());
        errdefer string.deinit();

        try json.stringify(object, .{}, string.writer());
        const result = try self.makeRequest(.POST, path, try string.toOwnedSlice());

        if (result.status != .no_content)
            return try json_helpers.parseLeft(DiscordError, void, self.allocator, try self.body.toOwnedSlice());

        return .ok({});
    }

    pub fn post5(self: *FetchReq, path: []const u8) !Result(void) {
        const result = try self.makeRequest(.POST, path, null);

        if (result.status != .no_content)
            return try json_helpers.parseLeft(DiscordError, void, self.allocator, try self.body.toOwnedSlice());

        return .ok({});
    }

    pub fn makeRequest(
        self: *FetchReq,
        method: http.Method,
        path: []const u8,
        to_post: ?[]const u8,
    ) MakeRequestError!http.Client.FetchResult {
        var buf: [256]u8 = undefined;
        const constructed = try std.fmt.bufPrint(&buf, "{s}{s}{s}", .{ BASE_URL, path, try self.formatQueryParams() });

        try self.extra_headers.append(http.Header{ .name = "Accept", .value = "application/json" });
        try self.extra_headers.append(http.Header{ .name = "Content-Type", .value = "application/json" });
        try self.extra_headers.append(http.Header{ .name = "Authorization", .value = self.token });

        var fetch_options = http.Client.FetchOptions{
            .location = http.Client.FetchOptions.Location{ .url = constructed },
            .method = method,
            .extra_headers = try self.extra_headers.toOwnedSlice(),
            .response_storage = .{ .dynamic = &self.body },
        };

        if (to_post != null) {
            fetch_options.payload = to_post;
        }

        const res = try self.client.fetch(fetch_options);
        return res;
    }

    pub fn makeRequestWithFiles(
        self: *FetchReq,
        method: http.Method,
        path: []const u8,
        to_post: []const u8,
        files: []const FileData,
    ) !http.Client.FetchResult {
        var form_fields = try std.ArrayList(FormField).initCapacity(self.allocator, files.len + 1);
        errdefer form_fields.deinit();

        for (files, 0..) |file, i|
            form_fields.appendAssumeCapacity(.{
                .name = try std.fmt.allocPrint(self.allocator, "files[{d}]", .{i}),
                .filename = file.filename,
                .value = file.value,
                .content_type = .{ .override = try file.type.string() },
            });

        form_fields.appendAssumeCapacity(.{
            .name = "payload_json",
            .value = to_post,
            .content_type = .{ .override = "application/json" },
        });

        var boundary: [64 + 3]u8 = undefined;
        std.debug.assert((std.fmt.bufPrint(
            &boundary,
            "{x:0>16}-{x:0>16}-{x:0>16}-{x:0>16}",
            .{ std.crypto.random.int(u64), std.crypto.random.int(u64), std.crypto.random.int(u64), std.crypto.random.int(u64) },
        ) catch unreachable).len == boundary.len);

        const body = try createMultiPartFormDataBody(
            self.allocator,
            &boundary,
            try form_fields.toOwnedSlice(),
        );

        const headers: std.http.Client.Request.Headers = .{
            .content_type = .{ .override = try std.fmt.allocPrint(self.allocator, "multipart/form-data; boundary={s}", .{boundary}) },
            .authorization = .{ .override = self.token },
        };

        var uri_buf: [256]u8 = undefined;
        const uri = try std.Uri.parse(try std.fmt.bufPrint(&uri_buf, "{s}{s}{s}", .{ BASE_URL, path, try self.formatQueryParams() }));

        var server_header_buffer: [16 * 1024]u8 = undefined;
        var request = try self.client.open(method, uri, .{
            .keep_alive = false,
            .server_header_buffer = &server_header_buffer,
            .headers = headers,
            .extra_headers = try self.extra_headers.toOwnedSlice(),
        });
        defer request.deinit();
        request.transfer_encoding = .{ .content_length = body.len };

        try request.send();
        try request.writeAll(body);

        try request.finish();
        try request.wait();

        try request.reader().readAllArrayList(&self.body, 2 * 1024 * 1024);

        if (request.response.status.class() == .success)
            return .{ .status = request.response.status };
        return error.FailedRequest; // TODO: make an Either type lol
    }
};

pub const FileData = struct {
    filename: []const u8,
    value: []const u8,
    type: union(enum) {
        jpg,
        jpeg,
        png,
        webp,
        gif,
        pub fn string(self: @This()) ![]const u8 {
            var buf: [256]u8 = undefined;
            return std.fmt.bufPrint(&buf, "image/{s}", .{@tagName(self)});
        }
    },
};

pub const FormField = struct {
    name: []const u8,
    filename: ?[]const u8 = null,
    content_type: std.http.Client.Request.Headers.Value = .default,
    value: []const u8,
};

fn createMultiPartFormDataBody(
    allocator: std.mem.Allocator,
    boundary: []const u8,
    fields: []const FormField,
) error{OutOfMemory}![]const u8 {
    var body: std.ArrayListUnmanaged(u8) = .{};
    errdefer body.deinit(allocator);
    const writer = body.writer(allocator);

    for (fields) |field| {
        try writer.print("--{s}\r\n", .{boundary});

        if (field.filename) |filename| {
            try writer.print("Content-Disposition: form-data; name=\"{s}\"; filename=\"{s}\"\r\n", .{ field.name, filename });
        } else {
            try writer.print("Content-Disposition: form-data; name=\"{s}\"\r\n", .{field.name});
        }

        switch (field.content_type) {
            .default => {
                if (field.filename != null) {
                    try writer.writeAll("Content-Type: application/octet-stream\r\n");
                }
            },
            .omit => {},
            .override => |content_type| {
                try writer.print("Content-Type: {s}\r\n", .{content_type});
            },
        }

        try writer.writeAll("\r\n");
        try writer.writeAll(field.value);
        try writer.writeAll("\r\n");
    }
    try writer.print("--{s}--\r\n", .{boundary});

    return try body.toOwnedSlice(allocator);
}
