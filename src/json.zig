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
//! ---------------------------------------------------------------------------------------------------------------------
//! JSON Parser
//! This is an implementation of a JSON parser written using the Zig standard library.
//! It uses monadic combinators to build an expressive PEG grammar that is extensible to other formats.
//! It leverages comptime for functional abstractions and type magic, enabling high-level APIs with zero runtime overhead.
//!
//! High-Level API Functions:
//! - `ultimateParser`: Parses any string or buffer, resolving data into a high-level `JsonType`.
//! - `parseIntoT`: Parses a `JsonType` and resolves it as a given struct type `T`.
//! - `parse`: Parses any string or buffer, directly resolving it as type `T` using an arena allocator.
//!
//! Example usage:
//! ```zig
//! const allocator = std.heap.GeneralPurposeAllocator(.{}){};
//! defer allocator.deinit();
//! const result = parseIntoT(MyStruct, "{ \"key\": \"value\" }", allocator);
//! ```
//! repo: https://hg.reactionary.software/repo/zjson/

const std = @import("std");
const mem = std.mem;

/// Error Definitions
pub const ParserError = error{
    /// JSON input is malformed (e.g., missing a closing brace).
    MalformedJson,
    /// A character is mismatched.
    UnexpectedCharacter,
    /// Input ran out before parsing completed.
    Empty,
    /// Memory allocation failed.
    OutOfMemory,
    /// Infinite recursion detected.
    InfiniteBehaviour,
    /// Type mismatch during parsing.
    TypeMismatch,
    /// Failed to parse number (int or float).
    NumberCastFail,
    /// A string is mismatched.
    MismatchedValue,
    /// unclosed bracket
    UnclosedBracket,
    /// unclosed curly braces
    UnclosedBraces,
    /// for `ultimateParserAssert`
    UnconsumedInput,
    /// unknown property
    UnknownProperty,
};

/// Parser a = String -> Either ParserError (String, a)
/// Functor and Applicative
pub fn Parser(comptime T: type) type {
    return fn ([]const u8, allocator: mem.Allocator) ParseResult(T);
}

/// error union, the result of a Functor a being called is a tuple (String, a)
/// which can further be piped onto another parser
pub fn ParseResult(comptime T: type) type {
    return ParserError!struct { []const u8, T };
}

/// Either a b = Left a | Right b
pub fn Either(comptime L: type, comptime R: type) type {
    return union(enum) {
        left: L,
        right: R,

        /// always returns .right
        pub fn unwrap(self: @This()) R {
            // discord.zig specifics
            if (@hasField(L, "code") and @hasField(L, "message") and self == .left)
                std.debug.panic("Error: {d}, {s}\n", .{ self.left.code, self.left.message });

            // for other libraries, it'll do this
            if (self == .left)
                std.debug.panic("Error: {any}\n", .{self.left});

            return self.right;
        }

        pub fn is(self: @This(), tag: std.meta.Tag(@This())) bool {
            return self == tag;
        }
    };
}

/// parser of the string `null`
pub fn jsonNull(str: []const u8, allocator: mem.Allocator) ParseResult(void) {
    const null_parser = stringP("null");

    const rem, const out = try null_parser(str, allocator);
    defer allocator.free(out);

    if (!mem.eql(u8, out, "null")) return error.MismatchedValue; // non null

    return .{ rem, {} };
}

/// parser of the string `true` or `false`
/// right means true
pub fn jsonBool(str: []const u8, allocator: mem.Allocator) ParseResult(bool) {
    const bool_parser = either([]const u8, []const u8, stringP("false"), stringP("true"));

    const rem, const out = try bool_parser(str, allocator);

    switch (out) {
        .left => |slice| {
            defer allocator.free(slice);
            if (!mem.eql(u8, slice, "false")) return error.MismatchedValue; // non false
            return .{ rem, false };
        },
        .right => |slice| {
            defer allocator.free(slice);
            if (!mem.eql(u8, slice, "true")) return error.MismatchedValue; // non true
            return .{ rem, true };
        },
    }
}

pub fn nonQuote(c: u8) bool {
    return c != '"';
}

pub fn isEscapeSeq(c: u8) bool {
    return c == '\\';
}

/// might throw out of bounds error
pub fn escapedSequence(str: []const u8, _: mem.Allocator) ParseResult(u8) {
    if (str.len == 0) return error.Empty;
    const char = str[0];

    return switch (char) {
        0x5C => if (str.len > 1 and str[1] == 0x22) .{ str[2..], str[1] } else .{ str[1..], char },
        0x22 => error.Empty,
        else => .{ str[1..], char },
    };
}

/// parser of any sequence of characters surrounded by "
/// handles escaping
pub fn jsonString(str: []const u8, allocator: mem.Allocator) ParseResult([]const u8) {
    const quote = term('"');
    const str2, _ = try quote(str, allocator);
    const str3, const string = try repeat(u8, escapedSequence)(str2, allocator);
    defer allocator.free(string);
    const str4, _ = try quote(str3, allocator);

    var characters: std.ArrayList(u8) = .init(allocator);
    errdefer characters.deinit();

    var i: usize = 0;
    while (i < string.len) {
        if (isEscapeSeq(string[i]) and i + 5 < string.len) switch (string[i + 1]) {
            inline 0x22, 0x5C, 0x2F => |d| try characters.append(d),
            'b' => try characters.append(0x8),
            'f' => try characters.append(0xC),
            'n' => try characters.append(0xA),
            'r' => try characters.append(0xD),
            't' => try characters.append(0x9),
            'u' => {
                const bytes = string[i + 2 .. i + 6];
                const code_point = std.fmt.parseInt(u21, bytes, 16) catch
                    return error.NumberCastFail;
                //std.debug.print("cp: {x} and bytes: {u}\n", .{ code_point, bytes });
                if (code_point <= 0x7F) {
                    try characters.append(@as(u8, @intCast(code_point)));
                } else if (code_point <= 0x7FF) {
                    try characters.append(0xC0 | (@as(u8, @intCast(code_point >> 6))));
                    try characters.append(0x80 | (@as(u8, @intCast(code_point & 0x3F))));
                } else if (code_point <= 0xFFFF) {
                    try characters.append(0xE0 | (@as(u8, @intCast(code_point >> 12))));
                    try characters.append(0x80 | (@as(u8, @intCast((code_point >> 6) & 0x3F))));
                    try characters.append(0x80 | (@as(u8, @intCast(code_point & 0x3F))));
                } else if (code_point <= 0x10FFFF) {
                    try characters.append(0xF0 | (@as(u8, @intCast(code_point >> 18))));
                    try characters.append(0x80 | (@as(u8, @intCast((code_point >> 12) & 0x3F))));
                    try characters.append(0x80 | (@as(u8, @intCast((code_point >> 6) & 0x3F))));
                    try characters.append(0x80 | (@as(u8, @intCast(code_point & 0x3F))));
                }
                i += 6;
                continue;
            },
            else => return error.MalformedJson,
        };

        if (string[i] < 0x20)
            return error.MalformedJson;
        try characters.append(string[i]);
        i += 1;
    }

    return .{ str4, try characters.toOwnedSlice() };
}

pub const JsonNumber = union(enum) {
    integer: i64,
    float: f64,

    /// to match against another JsonNumber
    pub fn is(self: JsonNumber, tag: std.meta.Tag(JsonNumber)) bool {
        return self == tag;
    }

    /// may only cast numeric types
    pub fn cast(self: JsonNumber, comptime T: type) T {
        return switch (self) {
            .integer => |i| switch (@typeInfo(T)) {
                .float => @as(T, @floatFromInt(i)),
                .int => @as(T, @intCast(i)),
                else => @compileError("not a number type"),
            },
            .float => |f| switch (@typeInfo(T)) {
                .float => @as(T, @floatCast(f)),
                .int => @as(T, @intFromFloat(f)),
                else => @compileError("not a number type"),
            },
        };
    }
};

/// caller owns returned memory
fn formatInt(allocator: mem.Allocator, sign: ?u8, digits: []const u8) mem.Allocator.Error![]const u8 {
    if (sign) |some_sign| return std.fmt.allocPrint(allocator, "{c}{s}", .{ some_sign, digits });
    return std.fmt.allocPrint(allocator, "{s}", .{digits});
}

/// caller owns returned memory
fn formatFloat(allocator: mem.Allocator, sign: ?u8, digits: []const u8, floating_point: ?[]const u8, exponent: ?[]const u8) mem.Allocator.Error![]const u8 {
    if (exponent) |some| {
        if (sign) |some_sign| return std.fmt.allocPrint(allocator, "{c}{s}.{s}{s}", .{ some_sign, digits, floating_point orelse "0", some });
        return std.fmt.allocPrint(allocator, "{s}.{s}{s}", .{ digits, floating_point orelse "0", some });
    } else {
        if (sign) |some_sign| return std.fmt.allocPrint(allocator, "{c}{s}.{s}", .{ some_sign, digits, floating_point orelse "0" });
        return std.fmt.allocPrint(allocator, "{s}.{s}", .{ digits, floating_point orelse "0" });
    }
}

fn parseExponent(str: []const u8, allocator: mem.Allocator) ParseResult([]const u8) {
    const digitParser = repeat(u8, satisfy(std.ascii.isDigit));

    const rem1, const e = try termIgnoreCase('e')(str, allocator); //ignore the e?
    const rem2, const maybe_sign = try optional(Either(u8, u8), either(u8, u8, term('-'), term('+')))(rem1, allocator);
    const rem3, const exponent = try digitParser(rem2, allocator);
    defer allocator.free(exponent);

    // maybe do a function to optimize this
    if (maybe_sign) |some| switch (some) {
        .left => |neg| {
            // eg: $(number)e-5
            const int = try std.fmt.allocPrint(allocator, "{c}{c}{s}", .{ e, neg, exponent });
            errdefer allocator.free(int);

            return .{ rem3, int };
        },
        .right => |pos| {
            // eg: $(number)e+5
            const int = try std.fmt.allocPrint(allocator, "{c}{c}{s}", .{ e, pos, exponent });
            errdefer allocator.free(int);

            return .{ rem3, int };
        },
    } else {
        // eg: $(number)e50
        const int = try std.fmt.allocPrint(allocator, "{c}{s}", .{ e, exponent });
        errdefer allocator.free(int);

        // no sign
        return .{ rem3, int };
    }
}

/// parser of either `integer` or `float` which can further be casted
/// onto the desired type
/// big integers bigger than `i64` are generally non sent throughout a JSON payload
/// as numbers but rather as strings, so it is unecessary to use a bigger integer size
pub fn jsonNumber(str: []const u8, allocator: mem.Allocator) ParseResult(JsonNumber) {
    const dot = term('.');
    const digitParser = repeat(u8, satisfy(std.ascii.isDigit));

    const str2, const maybe_sign = try optional(u8, term('-'))(str, allocator);
    const str3, const digits = try digitParser(str2, allocator);
    defer allocator.free(digits);

    const str4, _ = dot(str3, allocator) catch {
        // no floating point
        const rem, const exponent = try optional([]const u8, parseExponent)(str3, allocator);
        defer if (exponent) |some| allocator.free(some);

        if (exponent == null) {
            // it's an int eg: 150
            const printedi = try formatInt(allocator, maybe_sign, digits);
            defer allocator.free(printedi);
            const int = std.fmt.parseInt(i64, printedi, 10) catch
                return error.NumberCastFail;
            return .{ rem, .{ .integer = int } };
        } else {
            // it is a float eg: $(digits)e5 or $(digits)e+5
            const printedf = try formatFloat(allocator, maybe_sign, digits, null, exponent);
            defer allocator.free(printedf);
            const double = std.fmt.parseFloat(f64, printedf) catch
                return error.NumberCastFail;

            return .{ rem, .{ .float = double } };
        }
    };
    // it has floating points
    const str5, const floating_point = try digitParser(str4, allocator);
    defer allocator.free(floating_point);

    // it might have exponent
    const rem, const exponent = try optional([]const u8, parseExponent)(str5, allocator);
    defer if (exponent) |some| allocator.free(some);

    const printedf = try formatFloat(allocator, maybe_sign, digits, floating_point, exponent);
    defer allocator.free(printedf);

    const double = std.fmt.parseFloat(f64, printedf) catch
        return error.NumberCastFail;

    return .{ rem, .{ .float = double } };
}

/// parser of whitespaces
const whitespaces = repeat(u8, satisfy(std.ascii.isWhitespace));

/// parser of any JsonType surrounded by any number of whitespaces
/// it automatically frees the whitespaces, making the code drier
pub fn token(str: []const u8, allocator: mem.Allocator) ParseResult(JsonType) {
    const str2, const ws1 = try whitespaces(str, allocator);
    defer allocator.free(ws1);
    const str3, const val = try ultimateParser(str2, allocator);
    errdefer val.deinit(allocator);
    const str4, const ws2 = try whitespaces(str3, allocator);
    defer allocator.free(ws2);

    return .{ str4, val };
}

/// parser of any parser a surrounded by whitespaces
pub fn surroundingWhiteSpaces(comptime A: type, parser: Parser(A)) Parser(A) {
    return struct {
        fn f(str: []const u8, allocator: mem.Allocator) ParseResult(A) {
            const str2, const ws1 = try whitespaces(str, allocator);
            defer allocator.free(ws1);
            const str3, const val = try parser(str2, allocator);
            const str4, const ws2 = try whitespaces(str3, allocator);
            defer allocator.free(ws2);

            return .{ str4, val };
        }
    }.f;
}

/// parser of arrays
/// caller must free returned slice
pub fn jsonArray(str: []const u8, allocator: mem.Allocator) ParseResult([]JsonType) {
    const openBracket = surroundingWhiteSpaces(u8, term('['));
    const closedBracket = surroundingWhiteSpaces(u8, term(']'));
    const elements = sepBy(u8, JsonType, term(','), token);

    const str2, _ = try openBracket(str, allocator);
    const str3, const values = try elements(str2, allocator);
    errdefer allocator.free(values);
    errdefer for (values) |v| v.deinit(allocator);
    const str4, _ = try closedBracket(str3, allocator);

    return .{ str4, values };
}

test jsonArray {
    const data: []const u8 =
        \\ [""],
    ;
    const rem, const array = try jsonArray(data, std.testing.allocator);
    defer std.testing.allocator.free(array);
    _ = rem;
}

pub const JsonRawHashMap = std.StringHashMapUnmanaged(JsonType);

/// parser of `"key": value`
fn objPair(str: []const u8, allocator: mem.Allocator) ParseResult(struct { []const u8, JsonType }) {
    const colon = term(':');

    const str2, const key = surroundingWhiteSpaces([]const u8, jsonString)(str, allocator) catch |err| switch (err) {
        error.UnexpectedCharacter => return err, // expected key
        else => return err,
    };
    errdefer allocator.free(key);

    const str3, _ = colon(str2, allocator) catch |err| switch (err) {
        error.UnexpectedCharacter => return err, // expected colon
        else => return err,
    };

    const str4, const value = token(str3, allocator) catch |err| switch (err) {
        error.Empty => return err, // found key but no value
        else => return err,
    };
    errdefer value.deinit(allocator);

    return .{ str4, .{ key, value } };
}

/// parser for objects
/// caller is responsible of freeing the owned hashmap
/// `JsonRawHashMap` is an alias for an unmanaged hashmap as it helps reduce the memory footprint
/// this does not free the slices that the hashmap uses as keys, as it'd be undefined behaviour
pub fn jsonObject(str: []const u8, allocator: mem.Allocator) ParseResult(JsonRawHashMap) {
    const openingCurlyBrace = surroundingWhiteSpaces(u8, term('{'));
    const closingCurlyBrace = surroundingWhiteSpaces(u8, term('}'));
    const elements = sepBy(u8, struct { []const u8, JsonType }, term(','), objPair);
    const str2, _ = try openingCurlyBrace(str, allocator);
    const str3, const pairs = elements(str2, allocator) catch {
        const out, _ = try closingCurlyBrace(str2, allocator);
        return .{ out, .{} };
    };
    defer allocator.free(pairs);
    errdefer for (pairs) |kv| {
        const k, const v = kv;
        allocator.free(k);
        v.deinit(allocator);
    };
    const str4, _ = try closingCurlyBrace(str3, allocator);

    var obj: JsonRawHashMap = .{};
    errdefer obj.deinit(allocator);

    for (pairs) |kv| {
        const k, const v = kv;
        try obj.put(allocator, k, v);
    }

    return .{ str4, obj };
}

test jsonObject {
    const data: []const u8 =
        \\{"a":"b"}#
    ;

    const rem, var obj = try jsonObject(data, std.testing.allocator);
    defer obj.deinit(std.testing.allocator);

    var iterator = obj.iterator();
    while (iterator.next()) |kv| {
        const k = kv.key_ptr.*;
        const v = kv.value_ptr.*;
        defer std.testing.allocator.free(k);
        defer v.deinit(std.testing.allocator);
        std.debug.print("key: {s}, value: {any} and rem: {s}\n", .{ k, v, rem });
    }

    try std.testing.expect(rem.len == 1);
}

pub const JsonType = union(enum) {
    /// the identifier `null`
    null,

    /// either the identifier `true` or the identifier `false`
    bool: bool,

    /// the utf-8 string type, surrounded by backquotes
    string: []const u8,

    /// either a float or an int
    /// may be casted
    number: JsonNumber,

    /// JsonType surrounded by brackets, separated by commas
    array: []JsonType,

    /// the Object type, an unmanaged array hashmap, as keeping order might be useful for when printing
    /// usually a string which represents the name of the property, followed by a colon, then a JsonType, separated by commas
    object: JsonRawHashMap,

    pub fn is(self: JsonType, tag: std.meta.Tag(JsonType)) bool {
        return self == tag;
    }

    pub fn deinit(self: JsonType, allocator: mem.Allocator) void {
        switch (self) {
            .string => |slice| allocator.free(slice),
            .array => |slice| {
                for (slice) |val| val.deinit(allocator);
                allocator.free(slice);
            },
            .object => |obj| {
                defer @constCast(&obj).deinit(allocator);
                var it = obj.iterator();
                while (it.next()) |entry| {
                    allocator.free(entry.key_ptr.*);
                    entry.value_ptr.*.deinit(allocator);
                }
            },
            else => {},
        }
    }
};

/// entry point of the library
pub const ultimateParser: Parser(JsonType) = alternation(JsonType, .{
    jsonNull, // attempts to parse each type from top to bottom
    jsonBool,
    jsonString,
    jsonNumber,
    jsonArray,
    jsonObject,
});

/// same as ultimateParser but it errors out if it didn't consume the data
pub fn ultimateParserAssert(str: []const u8, allocator: mem.Allocator) ParserError!JsonType {
    const rem, const json = try ultimateParser(str, allocator);
    errdefer json.deinit(allocator);
    if (rem.len != 0) return error.UnconsumedInput;
    return json;
}

/// empty f void
pub fn empty() Parser(void) {
    return struct {
        fn f(str: []const u8, _: mem.Allocator) ParseResult(void) {
            return .{ str, {} };
        }
    }.f;
}

/// pure a -> f a
pub fn pure(comptime T: type, x: T) Parser(T) {
    return struct {
        fn f(str: []const u8, _: mem.Allocator) ParseResult(T) {
            return .{ str, x };
        }
    }.f;
}

/// fmap (a -> b) -> f a -> f b
pub fn fmap(
    comptime A: type,
    comptime B: type,
    comptime map: fn (A) B,
    parser: Parser(A),
) Parser(B) {
    return struct {
        fn f(str: []const u8, allocator: mem.Allocator) ParseResult(B) {
            const pofa = try parser(str, allocator);
            return .{ pofa[0], map(pofa[1]) };
        }
    }.f;
}

/// u8 -> bool -> f u8
pub fn satisfy(pred: fn (u8) bool) Parser(u8) {
    return struct {
        fn f(str: []const u8, _: mem.Allocator) ParseResult(u8) {
            if (str.len == 0) return error.Empty;
            return if (pred(str[0])) .{ str[1..], str[0] } else error.UnexpectedCharacter;
        }
    }.f;
}

/// parser of char
/// also: term char = satisfy (==char)
/// u8 -> f u8
pub fn term(char: u8) Parser(u8) {
    return struct {
        fn f(str: []const u8, _: mem.Allocator) ParseResult(u8) {
            return if (str.len == 0)
                error.Empty
            else if (str[0] == char)
                .{ str[1..], char }
            else
                error.UnexpectedCharacter;
        }
    }.f;
}

/// same as term
pub fn termIgnoreCase(char: u8) Parser(u8) {
    return struct {
        fn f(str: []const u8, _: mem.Allocator) ParseResult(u8) {
            return if (str.len == 0)
                error.Empty
            else if (std.ascii.toLower(str[0]) == std.ascii.toLower(char))
                .{ str[1..], char }
            else
                error.UnexpectedCharacter;
        }
    }.f;
}

/// must handle error.Empty
pub fn sepBy(
    comptime A: type,
    comptime B: type,
    parserA: Parser(A), // parser of separators
    parserB: Parser(B), // parser of elements
) Parser([]B) {
    return struct {
        fn f(str: []const u8, allocator: std.mem.Allocator) ParseResult([]B) {
            var bailing_allocator: BailingAllocator = .init(allocator);
            errdefer bailing_allocator.bail();

            var res: std.ArrayListUnmanaged(B) = .empty;
            errdefer res.deinit(allocator);

            const elemParser = repeat(struct { A, B }, join(A, B, parserA, parserB));
            // element
            const str2, const first = parserB(str, allocator) catch |err| switch (err) {
                error.Empty, error.MismatchedValue => {
                    res.deinit(allocator);
                    bailing_allocator.commit();
                    return .{ str, &.{} };
                },
                else => return err,
            };

            try res.append(allocator, first);

            // , element...
            const str3, const elems = elemParser(str2, allocator) catch {
                const slice_res = try res.toOwnedSlice(allocator);
                bailing_allocator.commit();
                return .{ str2, slice_res };
            };
            defer allocator.free(elems);

            for (elems) |pair| {
                _, const elem = pair;
                try res.append(allocator, elem);
            }

            const slice_res = try res.toOwnedSlice(allocator);
            bailing_allocator.commit();

            return .{ str3, slice_res };
        }
    }.f;
}

pub fn traverse(
    comptime A: type,
    comptime B: type,
    comptime map: fn (A) Parser(B),
    comptime slice: []const A,
) Parser([]A) {
    return struct {
        fn f(str: []const u8, allocator: std.mem.Allocator) ParseResult([]A) {
            var bailing_allocator: BailingAllocator = .init(allocator);
            errdefer bailing_allocator.bail();

            var res: std.ArrayListUnmanaged(A) = .empty;
            errdefer res.deinit(allocator);

            var str2 = str;

            inline for (slice) |item| {
                // record at the beginning of the iteration
                const len = str2.len;
                const parser = map(item);
                str2, const parsed = try parser(str2, allocator);
                if (len == str2.len) return error.InfiniteBehaviour;
                try res.append(allocator, parsed);
            }

            const slice_res = try res.toOwnedSlice(allocator);
            bailing_allocator.commit();

            return .{ str2, slice_res };
        }
    }.f;
}

/// repeat :: Functor f => f a -> f [a]
/// [] is Traversable*
/// repeats a parser until it fails
/// caller must free []A in Parser of []A
/// e*
pub fn repeat(comptime A: type, parser: Parser(A)) Parser([]A) {
    return struct {
        fn f(str: []const u8, allocator: std.mem.Allocator) ParseResult([]A) {
            var bailing_allocator: BailingAllocator = .init(allocator);
            errdefer bailing_allocator.bail();

            var res: std.ArrayListUnmanaged(A) = .empty;
            errdefer res.deinit(allocator);

            var str2 = str;

            while (true) {
                // record at the beginning of the iteration
                const len = str2.len;
                str2, const parsed = parser(str2, allocator) catch |err| switch (err) {
                    error.Empty, error.UnexpectedCharacter => break,
                    else => return err,
                };
                if (len == str2.len) return error.InfiniteBehaviour;
                try res.append(allocator, parsed);
            }

            const slice_res = try res.toOwnedSlice(allocator);
            bailing_allocator.commit();

            return .{ str2, slice_res };
        }
    }.f;
}

/// parser of any sequence of characters
/// caller must free []const u8 in Parser of []const u8
/// String -> f String
pub fn stringP(comptime str1: []const u8) Parser([]const u8) {
    return struct {
        fn f(str2: []const u8, allocator: mem.Allocator) ParseResult([]const u8) {
            const parser = traverse(u8, u8, term, str1);
            const remaining, const parsed = try parser(str2, allocator);

            if (!std.mem.eql(u8, str1, parsed)) return error.MismatchedValue;

            return .{ remaining, parsed };
        }
    }.f;
}

/// >>= :: Monad m => m a -> (a -> m b) -> m b
/// generally useless when doing FP in Zig
pub inline fn bind(comptime A: type, comptime B: type, parserA: Parser(A), map: fn (A) Parser(B)) Parser(B) {
    return struct {
        fn f(str: []const u8, allocator: mem.Allocator) ParseResult(B) {
            const pa = try parserA(str, allocator);
            const pb = try map(pa[0]);
            return .{ str, pb[1] };
        }
    }.f;
}

/// join :: f a -> f b -> f (a, b)
pub inline fn join(comptime A: type, comptime B: type, parserA: Parser(A), parserB: Parser(B)) Parser(struct { A, B }) {
    return struct {
        fn f(str: []const u8, allocator: mem.Allocator) ParseResult(struct { A, B }) {
            const str2, const pa = try parserA(str, allocator);
            const str3, const pb = try parserB(str2, allocator);
            return .{ str3, .{ pa, pb } };
        }
    }.f;
}

/// either :: f a -> f b -> f (Either a b)
pub inline fn either(comptime A: type, comptime B: type, parserA: Parser(A), parserB: Parser(B)) Parser(Either(A, B)) {
    return struct {
        fn f(str: []const u8, allocator: mem.Allocator) ParseResult(Either(A, B)) {
            const pa = parserA(str, allocator) catch {
                const pb = try parserB(str, allocator);
                return .{ pb[0], .{ .right = pb[1] } };
            };
            return .{ pa[0], .{ .left = pa[1] } };
        }
    }.f;
}

/// ap :: f (a -> b) -> f a -> f b
/// the S combinator
pub inline fn ap(comptime A: type, comptime B: type, parserA: Parser(fn (A) B), parserB: Parser(A)) Parser(B) {
    return struct {
        fn f(str: []const u8, allocator: mem.Allocator) ParseResult(B) {
            const stra, const pa = try parserA(str, allocator);
            const strb, const pb = try parserB(stra, allocator);
            return .{ strb, pa(pb) };
        }
    }.f;
}

/// kestrel a -> b -> a
/// the K combinator
pub inline fn kestrel(comptime A: type, comptime B: type, a: A) fn (B) A {
    return struct {
        fn f(_: B) A {
            return a;
        }
    }.f;
}

/// phoenix (a -> b -> c) -> f a -> f b -> f c
/// the S' combinator
pub inline fn phoenix(comptime A: type, comptime B: type, comptime C: type, map: fn (A, B) C, parserA: Parser(A), parserB: Parser(B)) Parser(C) {
    return struct {
        fn f(str: []const u8, allocator: mem.Allocator) ParseResult(C) {
            const stra, const pa = try parserA(str, allocator);
            const strb, const pb = try parserB(stra, allocator);
            return .{ strb, map(pa, pb) };
        }
    }.f;
}

/// general either
/// same as Either but with any other Union type
pub fn alternation(comptime Union: type, comptime field_parsers: FieldParsers(Union)) Parser(Union) {
    if (@typeInfo(Union) != .@"union" or
        @typeInfo(Union).@"union".tag_type == null) @compileError("expected a tagged `union` type");

    return struct {
        fn f(str: []const u8, allocator: mem.Allocator) ParseResult(Union) {
            inline for (field_parsers, std.meta.fields(Union)) |field_parser, field| {
                const rest, const parsed = field_parser(str, allocator) catch {
                    comptime continue;
                };
                return .{ rest, @unionInit(Union, field.name, parsed) };
            }
            return error.Empty;
        }
    }.f;
}

/// …?
/// notice how this combinator doesn't have any issues with memory leaks
pub fn optional(comptime T: type, parser: Parser(T)) Parser(?T) {
    return struct {
        fn f(str: []const u8, allocator: std.mem.Allocator) ParseResult(?T) {
            const rest, const parsed = parser(str, allocator) catch |err| return switch (err) {
                error.UnexpectedCharacter, error.Empty, error.NumberCastFail => .{ str, null },
                error.OutOfMemory => error.OutOfMemory,
                else => err,
            };
            return .{ rest, parsed };
        }
    }.f;
}

fn FieldParsers(T: type) type {
    var Types: []const type = &.{};
    for (std.meta.fields(T)) |field| Types = Types ++ .{Parser(field.type)};
    return std.meta.Tuple(Types);
}

pub const BailingAllocator = struct {
    child_allocator: std.mem.Allocator,
    responsibilities: std.MultiArrayList(Mem),

    const Mem = struct {
        ptr: [*]u8,
        len: usize,
        ptr_align: std.mem.Alignment,
    };

    fn init(child_allocator: std.mem.Allocator) BailingAllocator {
        return .{
            .child_allocator = child_allocator,
            .responsibilities = .empty,
        };
    }

    fn allocator(self: *BailingAllocator) std.mem.Allocator {
        return .{
            .ptr = self,
            .vtable = &.{ .alloc = alloc, .resize = resize, .free = free },
        };
    }

    /// disposes of this allocator, all allocated memory that were aquired via
    /// this allocator are to be freed via this allocator's `child_allocator`.
    fn commit(self: *BailingAllocator) void {
        self.responsibilities.deinit(self.child_allocator);
    }

    /// disposes of this allocator, frees all allocations made using this allocator.
    fn bail(self: *BailingAllocator) void {
        for (0..self.responsibilities.len) |i| {
            const memory = self.responsibilities.get(i);
            self.child_allocator.rawFree(memory.ptr[0..memory.len], memory.ptr_align, 0);
        }
        self.responsibilities.deinit(self.child_allocator);
    }

    fn alloc(ctx: *anyopaque, len: usize, ptr_align: std.mem.Alignment, _: usize) ?[*]u8 {
        const self: *BailingAllocator = @ptrCast(@alignCast(ctx));
        self.responsibilities.ensureUnusedCapacity(self.child_allocator, 1) catch return null;
        const ptr = self.child_allocator.rawAlloc(len, ptr_align, @returnAddress()) orelse return null;
        self.responsibilities.appendAssumeCapacity(.{ .len = len, .ptr = ptr, .ptr_align = ptr_align });
        return ptr;
    }

    fn resize(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, new_len: usize, _: usize) bool {
        const self: *BailingAllocator = @ptrCast(@alignCast(ctx));
        const res = self.child_allocator.rawResize(buf, buf_align, new_len, @returnAddress());
        if (res) {
            const i = std.mem.indexOfScalar([*]u8, self.responsibilities.items(.ptr), buf.ptr) orelse
                unreachable; // resized pointer must have been allocated beforehand.
            self.responsibilities.items(.len)[i] = new_len;
        }
        return res;
    }

    fn free(ctx: *anyopaque, buf: []u8, buf_align: std.mem.Alignment, _: usize) void {
        const self: *BailingAllocator = @ptrCast(@alignCast(ctx));
        self.child_allocator.rawFree(buf, buf_align, @returnAddress());

        const i = std.mem.indexOfScalar([*]u8, self.responsibilities.items(.ptr), buf.ptr) orelse
            unreachable; // freed pointer must have been allocated beforehand.
        _ = self.responsibilities.swapRemove(i);
    }
};

/// general join
/// useful for joining more than 2 parsers
pub fn sequence(comptime Struct: type, comptime parsers: FieldParsers(Struct)) Parser(Struct) {
    if (@typeInfo(Struct) != .@"struct")
        @compileError("expected a `struct` type");

    return struct {
        fn f(str: []const u8, allocator: std.mem.Allocator) ParseResult(Struct) {
            var bailing_allocator: BailingAllocator = .init(allocator);
            errdefer bailing_allocator.bail();

            var s: Struct = undefined;
            var rest = str;
            inline for (parsers, std.meta.fields(Struct)) |parser, field| {
                rest, const parsed = try parser(rest, bailing_allocator.allocator());
                @field(s, field.name) = parsed;
            }
            bailing_allocator.commit();
            return .{ rest, s };
        }
    }.f;
}

/// general repeat, same as repeat
/// e*
pub fn repetition(comptime T: type, parser: Parser(T)) Parser([]T) {
    return struct {
        fn f(str: []const u8, allocator: std.mem.Allocator) ParseResult([]T) {
            var bailing_allocator: BailingAllocator = .init(allocator);
            errdefer bailing_allocator.bail();

            var res: std.ArrayListUnmanaged(T) = .empty;
            errdefer res.deinit(allocator);

            var str2 = str;
            while (true) {
                str2, const parsed = parser(str2, bailing_allocator.allocator()) catch |err| switch (err) {
                    error.Empty, error.UnexpectedCharacter => break,
                    error.OutOfMemory => return err,
                };
                try res.append(allocator, parsed);
            }
            const slice_res = try res.toOwnedSlice(allocator);
            bailing_allocator.commit();
            return .{ str2, slice_res };
        }
    }.f;
}

pub const Error = std.mem.Allocator.Error || ParserError;

/// assumes that you are casting a type against its JsonType counterpart
///
/// u8, u16, u32...            -> assumes JsonNumber == .integer
/// i8, i16, i32...            -> assumes JsonNumber == .integer
/// f16, f32, f64              -> assumes JsonNumber == .float
/// array or slice of u8       -> JsonType.string
/// array or slice of T        -> JsonType.array
/// array of N elements        -> assumes JsonType.array.len == N
/// null                       -> JsonType.null
/// void                       -> ignores JsonType
/// ?T                         -> JsonType
/// *T                         -> JsonType, which always allocates memory
/// struct{..}                 -> JsonType.object
/// enum(..)                   -> if JsonNumber, assumes JsonNumber == .integer otherwise JsonType.string
/// union                      -> JsonType.string | JsonType.bool | JsonType.number
/// (empty) union(enum)        -> JsonType.string, the equivalent of `"a" | "b" | "c"` since values are `void`
/// tagged union               -> panics, use DiscriminatedUnion(U, key) instead
/// Record(T)                  -> JsonType.object
/// AssociativeArray(E, V)     -> JsonType.object (where keys are interpreted as enum 'E' members)
/// DiscriminatedUnion(U, key) -> JsonType.object (where a `key` that maps to `E` is present). Assumes that `U` is tagged by `E`
///
/// All other types are unsupported.
/// (Packed structs must be parsed manually, as the default parser of a `packed struct` is mirrored to one of an enum's)
///
/// If you must forcibly cast a type, you shall write a `json` method
/// the signature of the `json` function is as follows
/// ```
/// pub fn json(allocator: std.mem.Allocator, value: zjson.JsonType) !T
/// ```
/// where T is the type you must cast into
pub fn parseInto(comptime T: type, allocator: mem.Allocator, value: JsonType) Error!T {
    switch (@typeInfo(T)) {
        .void => return {},
        .bool => {
            return value.bool;
        },
        .int, .comptime_int => {
            std.debug.assert(value.number.is(.integer)); // attempting to cast an int against a non-int
            return value.number.cast(T);
        },
        .float, .comptime_float => {
            std.debug.assert(value.number.is(.float)); // attempting to cast a float against a non-float
            return value.number.cast(T);
        },
        .null => {
            std.debug.assert(value.is(.null)); // nullable or required property marked explicitly as null
            return null;
        },
        .optional => |optionalInfo| {
            if (value.is(.null)) return null;
            return try parseInto(optionalInfo.child, allocator, value); // optional
        },
        .@"union" => |unionInfo| {
            if (std.meta.hasFn(T, "json")) {
                return try T.json(allocator, value);
            }

            var result: ?T = null;

            if (unionInfo.tag_type == null) {
                switch (value) {
                    .string => |string| inline for (unionInfo.fields) |u_field| {
                        if (u_field.type == []const u8)
                            result = @unionInit(T, u_field.name, string);
                    },
                    .bool => |bool_| inline for (unionInfo.fields) |u_field| {
                        if (u_field.type == bool)
                            result = @unionInit(T, u_field.name, bool_);
                    },
                    .number => |number| inline for (unionInfo.fields) |u_field| {
                        switch (number) {
                            .integer => |i| if (u_field.type == @TypeOf(i)) {
                                result = @unionInit(T, u_field.name, i);
                            },
                            .float => |f| if (u_field.type == @TypeOf(f)) {
                                result = @unionInit(T, u_field.name, f);
                            },
                        }
                    },
                    else => return error.TypeMismatch, // may only cast string, bool, number
                }

                return result.?;
            }

            const fieldname = switch (value) {
                .string => |slice| slice,
                else => @panic("can only cast strings for tagged union"),
            };

            inline for (unionInfo.fields) |u_field| {
                if (std.mem.eql(u8, u_field.name, fieldname)) {
                    if (u_field.type == void) {
                        result = @unionInit(T, u_field.name, {});
                    } else {
                        @panic("tagged unions may only contain empty values");
                    }
                }
            }

            return result.?;
        },
        .@"enum" => {
            if (std.meta.hasFn(T, "json"))
                return try T.json(allocator, value);

            switch (value) {
                .string => return std.meta.stringToEnum(T, value.string).?, // useful for parsing a name into enum T
                .number => return @enumFromInt(value.number.integer), // forcibly casted
                else => return error.TypeMismatch,
            }
        },
        .@"struct" => |structInfo| {
            var r: T = undefined;
            if (std.meta.hasFn(T, "json"))
                return try T.json(allocator, value);

            if (structInfo.layout == .@"packed")
                return @bitCast(value.number.cast(structInfo.backing_integer.?)); // forcibly casted

            if (!value.is(.object))
                @panic("tried to cast a non-object into: " ++ @typeName(T));

            if (structInfo.is_tuple) inline for (0..structInfo.fields.len) |i| {
                r[i] = try parseInto(structInfo.fields[i].type, allocator, value.array[i]);
            };

            inline for (structInfo.fields) |field| {
                if (field.is_comptime) @compileError("comptime fields are not supported: " ++ @typeName(T) ++ "." ++ field.name);
                if (value.object.get(field.name)) |prop|
                    @field(r, field.name) = try parseInto(field.type, allocator, prop)
                else switch (@typeInfo(field.type)) {
                    .optional => @field(r, field.name) = null,
                    else => @panic("unknown property: " ++ field.name),
                }
            }

            return r;
        },
        .array => |arrayInfo| {
            switch (value) {
                .string => |string| {
                    if (arrayInfo.child != u8) return error.TypeMismatch; // attempting to cast an array of T against a string
                    std.debug.assert(arrayInfo.len == string.len);

                    var r: T = undefined;
                    comptime var i: usize = 0;
                    inline while (i < arrayInfo.len) : (i += 1)
                        r[i] = try parseInto(arrayInfo.child, allocator, string[i]);
                    return r;
                },
                .array => |array| {
                    std.debug.assert(arrayInfo.len == array.len);
                    var r: T = undefined;
                    comptime var i: usize = 0;
                    inline while (i < arrayInfo.len) : (i += 1)
                        r[i] = try parseInto(arrayInfo.child, allocator, array[i]);
                    return r;
                },
                else => return error.TypeMismatch,
            }
        },
        .pointer => |ptrInfo| switch (ptrInfo.size) {
            .one => {
                // we simply allocate the type and return an address instead of just returning the type
                const r: *ptrInfo.child = try allocator.create(ptrInfo.child);
                r.* = try parseInto(ptrInfo.child, allocator, value);
                return r;
            },
            .slice => switch (value) {
                .array => |array| {
                    var arraylist: std.ArrayList(ptrInfo.child) = .init(allocator);
                    try arraylist.ensureUnusedCapacity(array.len);
                    for (array) |jsonval| {
                        const item = try parseInto(ptrInfo.child, allocator, jsonval);
                        arraylist.appendAssumeCapacity(item);
                    }
                    if (ptrInfo.sentinel_ptr) |some| {
                        const sentinel = @as(*align(1) const ptrInfo.child, @ptrCast(some)).*;
                        return try arraylist.toOwnedSliceSentinel(sentinel);
                    }
                    return try arraylist.toOwnedSlice();
                },
                .string => |string| {
                    if (ptrInfo.child == u8) {
                        var arraylist: std.ArrayList(u8) = .init(allocator);
                        try arraylist.ensureUnusedCapacity(string.len);

                        for (string) |char|
                            arraylist.appendAssumeCapacity(char);

                        if (ptrInfo.sentinel_ptr) |some| {
                            const sentinel = @as(*align(1) const ptrInfo.child, @ptrCast(some)).*;
                            return try arraylist.toOwnedSliceSentinel(sentinel);
                        }

                        if (ptrInfo.is_const) {
                            arraylist.deinit();
                            return string;
                        } else {
                            arraylist.deinit();
                            const slice = try allocator.dupe(u8, string);
                            return @as(T, slice);
                        }
                        return try arraylist.toOwnedSlice();
                    }
                },
                else => return error.TypeMismatch, // may only cast string, array
            },
            else => {
                if (std.meta.hasFn(T, "json"))
                    return T.json(allocator, value);
                return error.TypeMismatch; // unsupported type
            },
        },
        else => @compileError("Unable to parse into type '" ++ @typeName(T) ++ "'"),
    }
    unreachable;
}

/// meant to handle a `JsonType` value and handling the deinitialization thereof
pub fn Owned(comptime T: type) type {
    return struct {
        arena: *std.heap.ArenaAllocator,
        value: T,

        pub fn deinit(self: @This()) void {
            const allocator = self.arena.child_allocator;
            self.arena.deinit();
            allocator.destroy(self.arena);
        }
    };
}

/// same as `Owned` but instead it handles 2 different values, generally `.right` is the correct one and `left` the error type
pub fn OwnedEither(comptime L: type, comptime R: type) type {
    return struct {
        value: Either(L, R),
        arena: *std.heap.ArenaAllocator,

        pub fn ok(ok_value: R) @This() {
            return .{ .value = ok_value };
        }

        pub fn err(err_value: L) @This() {
            return .{ .value = err_value };
        }

        pub fn deinit(self: @This()) void {
            const allocator = self.arena.child_allocator;
            self.arena.deinit();
            allocator.destroy(self.arena);
        }
    };
}

/// parse any string containing either a JSON object root `{...}` or a JSON array `[...]`
/// casts the value into `T`, read `parseInto` for detailed instructions
pub fn parse(comptime T: type, child_allocator: mem.Allocator, data: []const u8) ParserError!Owned(T) {
    var owned: Owned(T) = .{
        .arena = try child_allocator.create(std.heap.ArenaAllocator),
        .value = undefined,
    };
    owned.arena.* = .init(child_allocator);
    const allocator = owned.arena.allocator();
    const value = try ultimateParserAssert(data, allocator);
    owned.value = try parseInto(T, allocator, value);
    errdefer owned.arena.deinit();

    return owned;
}

/// same as `parse`
pub fn parseLeft(comptime L: type, comptime R: type, child_allocator: mem.Allocator, data: []const u8) ParserError!OwnedEither(L, R) {
    var owned: OwnedEither(L, R) = .{
        .arena = try child_allocator.create(std.heap.ArenaAllocator),
        .value = undefined,
    };
    owned.arena.* = .init(child_allocator);
    const allocator = owned.arena.allocator();
    const value = try ultimateParserAssert(data, allocator);
    owned.value = .{ .left = try parseInto(L, allocator, value) };
    errdefer owned.arena.deinit();

    return owned;
}

/// same as `parse`
pub fn parseRight(comptime L: type, comptime R: type, child_allocator: mem.Allocator, data: []const u8) ParserError!OwnedEither(L, R) {
    var owned: OwnedEither(L, R) = .{
        .arena = try child_allocator.create(std.heap.ArenaAllocator),
        .value = undefined,
    };
    owned.arena.* = .init(child_allocator);
    const allocator = owned.arena.allocator();
    const value = try ultimateParserAssert(data, allocator);
    owned.value = .{ .right = try parseInto(R, allocator, value) };
    errdefer owned.arena.deinit();

    return owned;
}

/// a hashmap for key value pairs
pub fn Record(comptime T: type) type {
    return struct {
        map: std.StringHashMapUnmanaged(T),
        pub fn json(allocator: mem.Allocator, value: JsonType) !@This() {
            var map: std.StringHashMapUnmanaged(T) = .empty;

            var iterator = value.object.iterator();

            while (iterator.next()) |pair| {
                const k = pair.key_ptr.*;
                const v = pair.value_ptr.*;

                errdefer allocator.free(k);
                errdefer v.deinit(allocator);
                try map.put(allocator, k, try parseInto(T, allocator, v));
            }

            return .{ .map = map };
        }
    };
}

/// a hashmap for key value pairs
/// where every key is an int
///
/// an example would be this
///
/// {
/// ...
///  "integration_types_config": {
///    "0": ...
///    "1": {
///      "oauth2_install_params": {
///        "scopes": ["applications.commands"],
///        "permissions": "0"
///      }
///    }
///  },
///  ...
/// }
/// this would help us map an enum member 0, 1, etc of type E into V
/// very useful stuff
/// internally, an EnumMap
pub fn AssociativeArray(comptime E: type, comptime V: type) type {
    if (@typeInfo(E) != .@"enum")
        @compileError("may only use enums as keys");

    return struct {
        map: std.EnumMap(E, V),
        pub fn json(allocator: mem.Allocator, value: JsonType) !@This() {
            var map: std.EnumMap(E, V) = .{};

            var iterator = value.object.iterator();

            while (iterator.next()) |pair| {
                const k = pair.key_ptr.*;
                const v = pair.value_ptr.*;

                defer allocator.free(k);
                errdefer v.deinit(allocator);

                // eg: enum(u8) would be @"enum".tag_type where tag_type is a u8
                const int = std.fmt.parseInt(@typeInfo(E).@"enum".tag_type, k, 10) catch unreachable;
                map.put(@enumFromInt(int), try parseInto(V, allocator, v));
            }

            return .{ .map = map };
        }
    };
}

/// assumes object.value[key] is of type `E` and the result thereof maps to the tagged union value
/// assumes `key` is a field present in all members of type `U`
/// eg: `type` is a property of type E and E.User maps to a User struct, whereas E.Admin maps to an Admin struct
pub fn DiscriminatedUnion(comptime U: type, comptime key: []const u8) type {
    if (@typeInfo(U) != .@"union")
        @compileError("may only cast a union");

    if (@typeInfo(U).@"union".tag_type == null)
        @compileError("cannot cast untagged union");

    const E = comptime @typeInfo(U).@"union".tag_type.?;

    if (@typeInfo(U).@"union".tag_type.? != E)
        @compileError("enum tag type of union(" ++ @typeName(U.@"union".tag_type) ++ ") doesn't match " ++ @typeName(E));

    return struct {
        t: U,
        pub fn json(allocator: mem.Allocator, value: JsonType) !@This() {
            if (!value.is(.object))
                @panic("coulnd't match against non-object type");

            const discriminator = value.object.get(key) orelse
                @panic("couldn't find property " ++ key ++ "in raw object");

            var u: U = undefined;

            const tag = discriminator.number.cast(@typeInfo(E).@"enum".tag_type);

            inline for (@typeInfo(E).@"enum".fields) |field| {
                if (field.value == tag) {
                    const T = comptime std.meta.fields(U)[field.value].type;
                    comptime std.debug.assert(@hasField(T, key));
                    u = @unionInit(U, field.name, try parseInto(T, allocator, value));
                }
            }

            return .{ .t = u };
        }
    };
}

test DiscriminatedUnion {
    // pretty simple stuff, in a real app you'd have thousands of these
    const AccountTypes = enum { user, admin };

    const User = struct {
        type: AccountTypes,
        id: u64,
        name: []const u8,
    };

    const Admin = struct {
        type: AccountTypes,
        id: u64,
        name: []const u8,
        admin: bool,
    };

    const Account = union(AccountTypes) {
        user: User,
        admin: Admin,
    };

    const payload =
        \\ {"type": 1, "id": 100000, "name": "Mathew", "admin": true}
    ;

    const data = try parse(DiscriminatedUnion(Account, "type"), std.testing.allocator, payload);
    defer data.deinit();

    try std.testing.expect(data.value.t == .admin);
    try std.testing.expect(data.value.t.admin.type == .admin);
    // we don't care otherwise about the data
}
