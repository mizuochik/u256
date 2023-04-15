const std = @import("std");
const testing = std.testing;
const fmt = std.fmt;

data: [4]u64,

const Self = @This();

pub fn fromHex(hex: []const u8) !Self {
    var data: [4]u64 = [_]u64{ 0, 0, 0, 0 };
    var i: u8 = 0;
    var end = hex.len;
    while (i < 4) : (i += 1) {
        var start = if (end > 16) end - 16 else 0;
        var j = start;
        while (j < end) : (j += 1) {
            data[i] <<= 4;
            data[i] += try std.fmt.parseInt(u64, hex[j .. j + 1], 16);
        }
        end = start;
    }
    return Self{ .data = data };
}

pub fn format(self: *const Self, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    try writer.print("{x:0>16}{x:0>16}{x:0>16}{x:0>16}", .{ self.data[3], self.data[2], self.data[1], self.data[0] });
}

pub fn eql(self: *const Self, other: *const Self) bool {
    var i = 0;
    var ans = true;
    while (i < 4) : (i += 1) {
        ans = ans and self.data[i] == other.data[i];
    }
    return ans;
}

pub fn add(x: *Self, y: *Self) Self {
    var z = Self{ .data = [4]u64{ 0, 0, 0, 0 } };
    var carry: u64 = 0;
    var i: u8 = 0;
    while (i < 4) : (i += 1) {
        const v = @addWithOverflow(x.data[i], y.data[i]);
        const w = @addWithOverflow(v[0], carry);
        z.data[i] = w[0];
        carry = v[1] + w[1];
    }
    return z;
}

pub fn sub(x: *Self, y: *Self) Self {
    var z = Self{ .data = [4]u64{ 0, 0, 0, 0 } };
    var carry: u64 = 0;
    var i: u8 = 0;
    while (i < 4) : (i += 1) {
        const v = @subWithOverflow(x.data[i], y.data[i]);
        const w = @subWithOverflow(v[0], carry);
        z.data[i] = w[0];
        carry = v[1] + w[1];
    }
    return z;
}

test "fromHex" {
    {
        const actual = try fromHex("ff");
        try testing.expectEqualDeep(Self{ .data = [4]u64{ 255, 0, 0, 0 } }, actual);
    }
    {
        const actual = try fromHex("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        try testing.expectEqualDeep(Self{ .data = [4]u64{ 18446744073709551615, 18446744073709551615, 18446744073709551615, 18446744073709551615 } }, actual);
    }
}

test "format" {
    {
        const actual = try fmt.allocPrint(testing.allocator, "{}", .{try fromHex("ff")});
        defer testing.allocator.free(actual);
        try testing.expectEqualStrings("00000000000000000000000000000000000000000000000000000000000000ff", actual);
    }
    {
        const actual = try fmt.allocPrint(testing.allocator, "{}", .{try fromHex("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff")});
        defer testing.allocator.free(actual);
        try testing.expectEqualStrings("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", actual);
    }
}

test "add" {
    {
        var x = try fromHex("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
        var y = try fromHex("5555555555555555555555555555555555555555555555555555555555555555");
        try testing.expectEqualDeep(try fromHex("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"), x.add(&y));
    }
    {
        var x = try fromHex("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");
        var y = try fromHex("1");
        try testing.expectEqualDeep(try fromHex("0"), x.add(&y));
    }
}

test "sub" {
    {
        var x = try fromHex("0000000000000000000000000000000000000000000000000000000000000000");
        var y = try fromHex("1");
        try testing.expectEqualDeep(try fromHex("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"), x.sub(&y));
    }
}
