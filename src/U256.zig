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

const U64Pair = struct {
    hi: u64,
    lo: u64,
};

const MASK32 = (1 << 32) - 1;

fn mul64(x: u64, y: u64) U64Pair {
    const x0 = x & MASK32;
    const x1 = x >> 32;
    const y0 = y & MASK32;
    const y1 = y >> 32;
    const w0 = @mulWithOverflow(x0, y0)[0];
    const t = @addWithOverflow(@mulWithOverflow(x1, y0)[0], w0 >> 32)[0];
    var w1 = t & MASK32;
    const w2 = t >> 32;
    w1 = @addWithOverflow(w1, @mulWithOverflow(x0, y1)[0]);
    return U64Pair{
        .hi = @addWithOverflow(@addWithOverflow(@mulWithOverflow(x1, y1)[0], w2)[0], w1 >> 32)[0],
        .lo = @mulWithOverflow(x, y)[0],
    };
}

// z + x * y
fn umulHop(z: u64, x: u64, y: u64) U64Pair {
    const v = mul64(x, y);
    const lo = @addWithOverflow(v.lo, z);
    const hi = @addWithOverflow(v.hi, lo[1]);
    return U64Pair{
        .hi = hi,
        .lo = lo,
    };
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
