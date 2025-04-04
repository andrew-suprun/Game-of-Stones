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
        const value_table = Self.valueTable();
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

        pub fn deinit(self: *Self) void {
            self.history.deinit();
            self.history_indices.deinit();
        }

        pub fn placeStone(self: *Self, place: Place, turn: Player) void {
            const scores = Self.score_table[@intFromEnum(turn)];
            self.history_indices.append(ScoreMark{ .place = place, .history_idx = self.history.items.len, .score = self.score }) catch {};

            const x: usize = @intCast(place.x);
            const y: usize = @intCast(place.y);

            if (turn == .first) {
                self.score += self.scores[y * size + x][@intFromEnum(Player.first)];
            } else {
                self.score -= self.scores[y * size + x][@intFromEnum(Player.second)];
            }

            {
                const x_start: usize = if (x + 1 > win_stones) x + 1 - win_stones else 0;
                const x_end: usize = @min(x + win_stones, size) - win_stones + 1;
                const n = x_end - x_start;
                self.updateRow(y * size + x_start, 1, n, scores);
            }

            {
                const y_start = if (y + 1 > win_stones) y + 1 - win_stones else 0;
                const y_end = @min(y + win_stones, size) - win_stones + 1;
                const n = y_end - y_start;
                self.updateRow(y_start * size + x, size, n, scores);
            }

            const m = 1 + @min(x, y, size - 1 - x, size - 1 - y);

            const c1 = size + 1 + x;
            const c2 = win_stones + y;
            const c3 = size + 1 + y;
            const c4 = win_stones + x;
            if (c1 >= c2 and c3 >= c4) {
                const n = @min(win_stones, m, c1 - c2, c3 - c4);
                const mn = @min(x, y, win_stones - 1);
                const x_start = x - mn;
                const y_start = y - mn;
                self.updateRow(y_start * size + x_start, size + 1, n, scores);
            }

            const c5 = win_stones + x + y;
            const c6 = x + y + 2;
            if (2 * size >= c5 and c6 >= win_stones) {
                const n = @min(win_stones, m, 2 * size - c5, c6 - win_stones);
                const mn = @min(size - 1 - x, y, win_stones - 1);
                const x_start = x + mn;
                const y_start = y - mn;
                self.updateRow(y_start * size + x_start, size - 1, n, scores);
            }

            self.places[y * size + x] = if (turn == .first) .black else .white;
        }

        pub fn removeStone(self: *Self) void {
            const idx = self.history_indices.pop().?;
            self.places[usize(idx.place.y) * size + usize(idx.place.x)] = .empty;
            self.score = idx.score;

            while (self.history.len > idx.history_idx) {
                const h_scores = self.history.pop().?;
                self.scores[h_scores.offset] = h_scores.scores;
            }
        }

        fn getPlaceAsUint(self: Self, offset: usize) usize {
            return @intCast(@intFromEnum(self.places[offset]));
        }

        fn updateRow(self: *Self, start: usize, delta: usize, n: usize, scores: [win_stones * win_stones + 1]Scores) void {
            for (0..win_stones - 1 + n) |ii| {
                const offset: usize = start + ii * delta;
                self.history.append(.{ .offset = offset, .scores = self.scores[ii] }) catch {};
            }

            var offset = start;
            var stones: usize = 0;

            inline for (0..win_stones - 1) |i| {
                stones += self.getPlaceAsUint(offset + i * delta);
            }

            for (0..n) |_| {
                stones += self.getPlaceAsUint(offset + delta * (win_stones - 1));
                const placeScores = scores[stones];
                if (placeScores[0] != 0 or placeScores[1] != 0) {
                    inline for (0..win_stones) |j| {
                        self.scores[offset + j * delta] += placeScores;
                    }
                }
                stones -= self.getPlaceAsUint(offset);
                offset += delta;
            }
        }

        // fn boardValue(self: Self) Score {
        //     var value: Score = 0;
        //     for (0..size) |y| {
        //         var stones: i8 = 0;
        //         for (0..win_stones - 1) |x| {
        //             stones += self.places[y * size + x];
        //         }
        //         for (0..size - win_stones + 1) |x| {
        //             stones += self.places[y * size + x + win_stones - 1];
        //             value += self.calc_value(stones, self.value_table);
        //             stones -= self.places[y * size + x];
        //         }
        //     }
        //     return value;
        // }

        fn valueTable() [win_stones + 1]Score {
            return score_blk: {
                var list: [win_stones + 1]Score = undefined;
                list[0] = 0;
                list[1] = 1;
                for (2..win_stones) |i| {
                    list[i] = list[i - 1] * 5;
                }
                list[win_stones] = std.math.inf(Score);
                break :score_blk list;
            };
        }

        fn scoreTable() [2][win_stones * win_stones + 1]Scores {
            const result_size = win_stones * win_stones + 1;
            const scores = valueTable();

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

test "updateRow" {
    const B = Board(19, 6);
    var board = B.init(std.testing.allocator);
    board.placeStone(.{ .x = 0, .y = 0 }, .first);
    board.placeStone(.{ .x = 0, .y = 18 }, .first);
    board.placeStone(.{ .x = 18, .y = 0 }, .first);
    board.placeStone(.{ .x = 18, .y = 18 }, .first);
    board.updateRow(18, 18, 6, B.score_table[0]);
    for (0..19) |y| {
        for (0..19) |x| {
            std.debug.print("{d} ", .{board.scores[y * 19 + x][0]});
        }
        std.debug.print("\n", .{});
    }
    board.deinit();
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

// Benchmarks
pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    const allocator = arena.allocator();

    const B = Board(19, 6);
    var board = B.init(allocator);
    var timer = try std.time.Timer.start();
    for (0..10) |_| {
        for (0..1_000) |_| {
            board.updateRow(18, 18, 6, B.score_table[0]);
            // _ = arena.reset(.free_all);
            // std.mem.doNotOptimizeAway(board);
        }
        const dur = timer.lap();
        std.debug.print("{d} msec\n", .{@as(f64, @floatFromInt(dur)) / 1_000_000});
    }
}
