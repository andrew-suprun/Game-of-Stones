const std = @import("std");

fn scoreTable(comptime Score: type, comptime max_stones: isize, comptime scores: [max_stones + 1]Score) [2][max_stones * max_stones + 1]@Vector(2, Score) {
    const Scores = @Vector(2, Score);
    const result_size = max_stones * max_stones + 1;

    const v2 = blk: {
        var values: [max_stones]Scores = undefined;
        values[0] = Scores{ 1, -1 };
        for (0..max_stones - 1) |i| {
            values[i + 1] = Scores{ scores[i + 2] - scores[i + 1], -scores[i + 1] };
        }
        break :blk values;
    };

    return blk: {
        var result: [2][result_size]Scores = .{ [1]Scores{.{ 0, 0 }} ** result_size, [1]Scores{.{ 0, 0 }} ** result_size };
        for (0..max_stones - 1) |i| {
            result[0][i * max_stones] = Scores{ v2[i][1], -v2[i][0] };
            result[0][i] = Scores{ v2[i + 1][0] - v2[i][0], v2[i][1] - v2[i + 1][1] };
            result[1][i] = Scores{ -v2[i][0], v2[i][1] };
            result[1][i * max_stones] = Scores{ v2[i][1] - v2[i + 1][1], v2[i + 1][0] - v2[i][0] };
        }
        break :blk result;
    };
}

test {
    const table = scoreTable(f32, 5, [_]f32{ 0, 1, 5, 25, 125, std.math.inf(f32) });
    for (0..5) |y| {
        for (0..5) |x| {
            const f = table[0][y * 5 + x];
            std.debug.print("{d}, {d} | ", .{ f[0], f[1] });
        }
        std.debug.print("\n", .{});
    }
}
