const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const Score = f32;
const Scores = @Vector(2, Score);

const Place = struct {
    x: i8,
    y: i8,
};

const PlaceScores = struct {
    offset: usize,
    scores: Scores,
};

const ScoreMark = struct {
    place: Place,
    score: Score,
    history_idx: usize,
};

pub fn Board(comptime size: comptime_int, comptime win_stones: comptime_int) type {
    return struct {
        pub const Player = enum { first, second };

        const Self = @This();
        const Stone = enum(i8) { none, black, white = win_stones };
        const score_table = Self.scoreTable();

        score: Score = 0,
        places: [size * size]Stone = [1]Stone{.none} ** (size * size),
        scores: [size * size]Scores = scores_blk: {
            var values = [1]Scores{.{ 0, 0 }} ** (size * size);
            for (0..size) |yy| {
                const y: Score = @floatFromInt(yy);
                const v = @min(win_stones, y + 1, size - y);
                for (0..size) |xx| {
                    const x: Score = @floatFromInt(xx);
                    const stones: Score = win_stones;
                    const h: Score = @min(stones, x + 1, size - x);
                    const m: Score = @min(x + 1, y + 1, size - x, size - y);
                    const t1: Score = @max(0, @min(stones, m, size - stones + 1 - y + x, size - stones + 1 - x + y));
                    const t2: Score = @max(0, @min(stones, m, 2 * size - 1 - stones + 1 - y - x, x + y - stones + 1 + 1));
                    const total = v + h + t1 + t2;
                    values[yy * size + xx] = Scores{ total, total };
                }
            }
            break :scores_blk values;
        },
        history: ArrayList(PlaceScores),
        history_indices: ArrayList(ScoreMark),

        pub fn init(allocator: Allocator) Self {
            return Self{
                .history = ArrayList(PlaceScores).init(allocator),
                .history_indices = ArrayList(ScoreMark).init(allocator),
            };
        }

        pub fn deinit(self: *Self) Self {
            self.history.deinit();
            self.history_indices.deinit();
        }

        fn scoreTable() [2][win_stones * win_stones + 1]Scores {
            const result_size = win_stones * win_stones + 1;
            const scores = score_blk: {
                var list: [win_stones + 1]Score = undefined;
                list[0] = 0;
                list[1] = 1;
                for (2..win_stones) |i| {
                    list[i] = list[i - 1] * 5;
                }
                list[win_stones] = std.math.inf(Score);
                break :score_blk list;
            };

            const v2 = blk: {
                var values: [win_stones]Scores = undefined;
                values[0] = Scores{ 1, -1 };
                for (0..win_stones - 1) |i| {
                    values[i + 1] = Scores{ scores[i + 2] - scores[i + 1], -scores[i + 1] };
                }
                break :blk values;
            };

            return blk: {
                var result: [2][result_size]Scores = .{ [1]Scores{.{ 0, 0 }} ** result_size, [1]Scores{.{ 0, 0 }} ** result_size };
                for (0..win_stones - 1) |i| {
                    result[0][i * win_stones] = Scores{ v2[i][1], -v2[i][0] };
                    result[0][i] = Scores{ v2[i + 1][0] - v2[i][0], v2[i][1] - v2[i + 1][1] };
                    result[1][i] = Scores{ -v2[i][0], v2[i][1] };
                    result[1][i * win_stones] = Scores{ v2[i][1] - v2[i + 1][1], v2[i + 1][0] - v2[i][0] };
                }
                break :blk result;
            };
        }
    };
}

test "print_score_table" {
    const board = Board(19, 6).init(std.testing.allocator);
    std.debug.print("{any}\n", .{Board(19, 5).score_table});
    for (0..19) |y| {
        for (0..19) |x| {
            std.debug.print("{d} ", .{board.scores[y * 19 + x][0]});
        }
        std.debug.print("\n", .{});
    }
}
