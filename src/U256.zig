const std = @import("std");
const testing = std.testing;

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
