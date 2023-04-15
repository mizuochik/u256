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
