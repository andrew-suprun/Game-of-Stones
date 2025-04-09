const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const pr = std.debug.print;

const game = @import("game.zig");
const score = @import("score.zig");
const Player = game.Player;
const Decision = game.Decision;
const Heap = @import("heap.zig").Heap;

const Scores = @Vector(2, f32);

pub const Place = struct {
    x: usize,
    y: usize,

    pub fn init(text: []const u8) !Place {
        if (text.len < 2 or text.len > 3) return error.ParseError;
        if (text[0] < 'a' or text[0] > 't') return error.ParseError;
        const x: usize = text[0] - 'a';
        const y1: usize = std.fmt.parseUnsigned(usize, text[1..], 10) catch return error.ParseError;
        return .{ .x = x, .y = y1 - 1 };
    }

    pub fn str(self: Place, buf: []u8) []u8 {
        std.debug.assert(buf.len >= 3);
        buf[0] = @as(u8, @intCast(self.x)) + 'a';
        const y = std.fmt.bufPrint(buf[1..], "{d}", .{self.y + 1}) catch unreachable;
        return buf[0 .. y.len + 1];
    }

    pub fn eql(a: Place, b: Place) bool {
        return a.x == b.x and a.y == b.y;
    }
};

test "parsePlace" {
    const place = try Place.init("s19");
    try std.testing.expect(place.eql(Place{ .x = 18, .y = 18 }));
    var buf: [3]u8 = undefined;
    const str = place.str(buf[0..]);
    try std.testing.expect(std.mem.eql(u8, "s19", str));
}

const PlaceScores = struct {
    offset: usize,
    scores: Scores,
};

const ScoreMark = struct {
    place: Place,
    score: f32,
    history_idx: usize,
};

const PlaceScore = struct {
    place: Place,
    score: f32,
};

fn less(a: PlaceScore, b: PlaceScore) bool {
    return a.score < b.score;
}

pub fn Board(comptime size: comptime_int, comptime win_stones: comptime_int, max_places: comptime_int) type {
    return struct {
        score: f32 = 0,
        places: [size * size]Stone = [1]Stone{.none} ** (size * size),
        scores: [size * size]Scores = scores_blk: {
            var values = [1]Scores{.{ 0, 0 }} ** (size * size);
            for (0..size) |yy| {
                const y: isize = @intCast(yy);
                const v = @min(win_stones, y + 1, size - y);
                for (0..size) |xx| {
                    const x: isize = @intCast(xx);
                    const stones: isize = win_stones;
                    const h: isize = @min(stones, x + 1, size - x);
                    const m: isize = @min(x + 1, y + 1, size - x, size - y);
                    const t1 = @max(0, @min(stones, m, size - stones + 1 - y + x, size - stones + 1 - x + y));
                    const t2 = @max(0, @min(stones, m, 2 * size - 1 - stones + 1 - y - x, x + y - stones + 2));
                    const total: f32 = @floatFromInt(v + h + t1 + t2);
                    values[y * size + x] = Scores{ total, total };
                }
            }
            break :scores_blk values;
        },
        history: ArrayList(PlaceScores),
        history_indices: ArrayList(ScoreMark),
        heap: Heap(PlaceScore, max_places, less) = .{},

        const Self = @This();
        const Stone = enum(u8) { none, black, white = win_stones };
        const value_table = Self.valueTable();
        const score_table = Self.scoreTable();

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

            const x = place.x;
            const y = place.y;

            if (turn == .first) {
                self.score += self.scores[y * size + x][@intFromEnum(Player.first)];
            } else {
                self.score -= self.scores[y * size + x][@intFromEnum(Player.second)];
            }

            {
                const x_start = if (x + 1 > win_stones) x + 1 - win_stones else 0;
                const x_end = @min(x + win_stones, size) - win_stones + 1;
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
            self.places[idx.place.y * size + idx.place.x] = .none;
            self.score = idx.score;

            while (self.history.items.len > idx.history_idx) {
                const h_scores = self.history.pop().?;
                self.scores[h_scores.offset] = h_scores.scores;
            }
        }

        pub fn topPlaces(self: *Self, comptime turn: Player) []PlaceScore {
            self.heap.clear();
            for (0..size) |y| {
                for (0..size) |x| {
                    const offset = y * size + x;
                    const scores = self.scores[offset];
                    const place_score = if (turn == .first) scores[0] else scores[1];
                    if (self.places[offset] == .none and place_score > 0) {
                        self.heap.add(PlaceScore{ .place = Place{ .x = x, .y = y }, .score = place_score });
                    }
                }
            }
            return self.heap.items();
        }

        pub fn decision(self: Self) Decision {
            for (0..size) |a| {
                var hStones = Scores{ 0, 0 };
                var vStones = Scores{ 0, 0 };
                for (0..win_stones - 1) |b| {
                    hStones += counts(self.places[a * size + b]);
                    vStones += counts(self.places[b * size + a]);
                }
                for (0..size - win_stones + 1) |b| {
                    hStones += counts(self.places[a * size + b + win_stones - 1]);
                    vStones += counts(self.places[(b + win_stones - 1) * size + a]);
                    if (hStones[0] == win_stones or vStones[0] == win_stones) {
                        return .first_win;
                    } else if (hStones[1] == win_stones or vStones[1] == win_stones) {
                        return .second_win;
                    }
                    hStones -= counts(self.places[a * size + b]);
                    vStones -= counts(self.places[b * size + a]);
                }
            }

            for (0..size - win_stones + 1) |y| {
                var stones1 = Scores{ 0, 0 };
                var stones2 = Scores{ 0, 0 };
                for (0..win_stones - 1) |x| {
                    stones1 += counts(self.places[(y + x) * size + x]);
                    stones2 += counts(self.places[(x + y) * size + size - 1 - x]);
                }
                for (0..size - win_stones + 1 - y) |x| {
                    stones1 += counts(self.places[(x + y + win_stones - 1) * size + x + win_stones - 1]);
                    stones2 += counts(self.places[(x + y + win_stones - 1) * size + size - x - win_stones]);
                    if (stones1[0] == win_stones or stones2[0] == win_stones) {
                        return .first_win;
                    } else if (stones1[1] == win_stones or stones2[1] == win_stones) {
                        return .second_win;
                    }
                    stones1 -= counts(self.places[(y + x) * size + x]);
                    stones2 -= counts(self.places[(x + y) * size + size - 1 - x]);
                }
            }

            for (1..size - win_stones + 1) |x| {
                var stones1 = Scores{ 0, 0 };
                var stones2 = Scores{ 0, 0 };
                for (0..win_stones - 1) |y| {
                    stones1 += counts(self.places[y * size + x + y]);
                    stones2 += counts(self.places[y * size + size - 1 - x - y]);
                }
                for (0..size - win_stones + 1 - x) |y| {
                    stones1 += counts(self.places[(y + win_stones - 1) * size + x + y + win_stones - 1]);
                    stones2 += counts(self.places[(y + win_stones - 1) * size + size - win_stones - x - y]);
                    if (stones1[0] == win_stones or stones2[0] == win_stones) {
                        return .first_win;
                    } else if (stones1[1] == win_stones or stones2[1] == win_stones) {
                        return .second_win;
                    }
                    stones1 -= counts(self.places[y * size + x + y]);
                    stones2 -= counts(self.places[y * size + size - 1 - x - y]);
                }
            }

            for (0..size * size) |offset| {
                if (self.places[offset] == .none and self.scores[offset][0] > 1) {
                    return .no_decision;
                }
            }
            return .no_decision;
        }

        inline fn counts(stone: Stone) Scores {
            return switch (stone) {
                .none => Scores{ 0, 0 },
                .black => Scores{ 1, 0 },
                .white => Scores{ 0, 1 },
            };
        }

        pub fn print(self: Self) void {
            pr("\n  ", .{});

            for (0..size) |i| {
                const c: u8 = @intCast(i);
                pr(" {c}", .{c + 'a'});
            }
            pr("\n", .{});

            for (0..size) |y| {
                pr("{:2} ", .{y + 1});
                for (0..size) |x| {
                    const stone = self.places[y * size + x];
                    switch (stone) {
                        .black => if (x == 0) pr(" X", .{}) else pr("─X", .{}),
                        .white => if (x == 0) pr(" O", .{}) else pr("─O", .{}),
                        .none => {
                            switch (y) {
                                0 => {
                                    switch (x) {
                                        0 => pr(" ┌", .{}),
                                        size - 1 => pr("─┐", .{}),
                                        else => pr("─┬", .{}),
                                    }
                                },
                                size - 1 => {
                                    switch (x) {
                                        0 => pr(" └", .{}),
                                        size - 1 => pr("─┘", .{}),
                                        else => pr("─┴", .{}),
                                    }
                                },
                                else => {
                                    switch (x) {
                                        0 => pr(" ├", .{}),
                                        size - 1 => pr("─┤", .{}),
                                        else => pr("─┼", .{}),
                                    }
                                },
                            }
                        },
                    }
                }
                pr(" {:2}\n", .{y + 1});
            }
            pr("  ", .{});
            for (0..size) |i| {
                const c: u8 = @intCast(i);
                pr(" {c}", .{c + 'a'});
            }
            pr("\n", .{});
        }

        pub fn printScores(self: Self) void {
            self.printScoresForPlayer(.first);
            self.printScoresForPlayer(.second);
        }

        fn printScoresForPlayer(self: Self, player: Player) void {
            const idx = @intFromEnum(player);
            pr("\n   │", .{});
            for (0..size) |i| {
                const c: u8 = @intCast(i);
                pr("    {c} ", .{c + 'a'});
            }
            pr("│\n───┼" ++ "──────" ** size ++ "┼───\n", .{});
            for (0..size) |y| {
                pr("{d:2} │", .{y + 1});
                for (0..size) |x| {
                    const stone = self.places[y * size + x];
                    switch (stone) {
                        .none => pr("{d:5} ", .{self.scores[y * size + x][idx]}),
                        .black => pr("    X ", .{}),
                        .white => pr("    O ", .{}),
                    }
                }
                pr("| {d:2}\n", .{y + 1});
            }
            pr("───┼" ++ "──────" ** size ++ "┼───", .{});
            if (idx == 1) {
                pr("\n   │", .{});
                for (0..size) |i| {
                    const c: u8 = @intCast(i);
                    pr("    {c} ", .{c + 'a'});
                }
                pr("│\n", .{});
            }
        }

        fn getPlace(self: Self, offset: usize) usize {
            return @intCast(@intFromEnum(self.places[offset]));
        }

        pub inline fn getScores(self: Self, place: Place) Scores {
            return self.scores[place.y * size + place.x];
        }

        fn updateRow(self: *Self, start: usize, delta: usize, n: usize, scores: [win_stones * win_stones + 1]Scores) void {
            for (0..win_stones - 1 + n) |ii| {
                const offset = start + ii * delta;
                self.history.append(.{ .offset = offset, .scores = self.scores[offset] }) catch {};
            }

            var offset = start;
            var stones: usize = 0;

            inline for (0..win_stones - 1) |i| {
                stones += self.getPlace(offset + i * delta);
            }

            for (0..n) |_| {
                stones += self.getPlace(offset + delta * (win_stones - 1));
                const placeScores = scores[stones];
                if (placeScores[0] != 0 or placeScores[1] != 0) {
                    inline for (0..win_stones) |j| {
                        self.scores[offset + j * delta] += placeScores;
                    }
                }
                stones -= self.getPlace(offset);
                offset += delta;
            }
        }

        pub fn maxScore(self: Self, player: Player) f32 {
            const idx = @intFromEnum(player);
            var r = score.loss;
            for (self.scores, 0..) |place_score, i| {
                const playerScore = place_score[idx];
                if (r < playerScore and self.places[i] == .none) {
                    r = playerScore;
                }
            }
            return r;
        }

        fn boardValue(self: Self) f32 {
            var value: f32 = 0;
            for (0..size) |y| {
                var stones: usize = 0;
                for (0..win_stones - 1) |x| {
                    stones += self.getPlace(y * size + x);
                }
                for (0..size - win_stones + 1) |x| {
                    stones += self.getPlace(y * size + x + win_stones - 1);
                    value += Self.calcValue(stones);
                    stones -= self.getPlace(y * size + x);
                }
            }

            for (0..size) |x| {
                var stones: usize = 0;
                for (0..win_stones - 1) |y| {
                    stones += self.getPlace(y * size + x);
                }
                for (0..size - win_stones + 1) |y| {
                    stones += self.getPlace((y + win_stones - 1) * size + x);
                    value += Self.calcValue(stones);
                    stones -= self.getPlace(y * size + x);
                }
            }

            for (0..size - win_stones + 1) |y| {
                var stones: usize = 0;
                for (0..win_stones - 1) |x| {
                    stones += self.getPlace((x + y) * size + x);
                }
                for (0..size - win_stones + 1 - y) |x| {
                    stones += self.getPlace((x + y + win_stones - 1) * size + x + win_stones - 1);
                    value += Self.calcValue(stones);
                    stones -= self.getPlace((x + y) * size + x);
                }
            }

            for (1..size - win_stones + 1) |x| {
                var stones: usize = 0;
                for (0..win_stones - 1) |y| {
                    stones += self.getPlace(y * size + x + y);
                }
                for (0..size - win_stones + 1 - x) |y| {
                    stones += self.getPlace((y + win_stones - 1) * size + x + y + win_stones - 1);
                    value += Self.calcValue(stones);
                    stones -= self.getPlace(y * size + x + y);
                }
            }

            for (0..size - win_stones + 1) |y| {
                var stones: usize = 0;
                for (0..win_stones - 1) |x| {
                    stones += self.getPlace((x + y) * size + size - 1 - x);
                }
                for (0..size - win_stones + 1 - y) |x| {
                    stones += self.getPlace((x + y + win_stones - 1) * size + size - 1 - x - win_stones + 1);
                    value += Self.calcValue(stones);
                    stones -= self.getPlace((x + y) * size + size - 1 - x);
                }
            }

            for (1..size - win_stones + 1) |x| {
                var stones: usize = 0;
                for (0..win_stones - 1) |y| {
                    stones += self.getPlace(y * size + size - 1 - x - y);
                }
                for (0..size - win_stones + 1 - x) |y| {
                    stones += self.getPlace((y + win_stones - 1) * size + size - win_stones - x - y);
                    value += Self.calcValue(stones);
                    stones -= self.getPlace(y * size + size - 1 - x - y);
                }
            }

            return value;
        }

        fn calcValue(stones: usize) f32 {
            const black = stones % win_stones;
            const white = stones / win_stones;
            return if (white == 0) Self.value_table[black] else if (black == 0) -Self.value_table[white] else 0;
        }

        fn valueTable() [win_stones + 1]f32 {
            return score_blk: {
                var list: [win_stones + 1]f32 = undefined;
                list[0] = 0;
                list[1] = 1;
                for (2..win_stones) |i| {
                    list[i] = list[i - 1] * 5;
                }
                list[win_stones] = score.win;
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

test "placeStone" {
    var rng = std.Random.DefaultPrng.init(2);
    var board = Board(19, 6, 8).init(std.testing.allocator);
    defer board.deinit();

    var value: f32 = 0;
    for (1..360) |_| {
        var failure = false;
        for (0..19) |y| {
            for (0..19) |x| {
                if (board.places[y * 19 + x] == .none) {
                    const actual = board.scores[y * 19 + x];
                    board.placeStone(Place{ .x = x, .y = y }, .first);
                    var expected = board.boardValue() - value;
                    board.removeStone();
                    if (actual[0] != expected) {
                        pr("Black: x={d} y={d} actual={d} expected={d}\n", .{ x, y, actual[0], expected });
                        failure = true;
                    }
                    board.placeStone(Place{ .x = x, .y = y }, .second);
                    expected = value - board.boardValue();
                    board.removeStone();
                    if (actual[1] != expected) {
                        pr("White: x={d} y={d} actual={d} expected={d}\n", .{ x, y, actual[1], expected });
                        failure = true;
                    }
                }
            }
        }
        if (failure) {
            board.print();
            board.printScores();
            try std.testing.expect(false);
        }
        const x: usize = rng.next() % 19;
        const y: usize = rng.next() % 19;
        if (board.places[y * 19 + x] == .none) {
            const turn: u1 = @truncate(rng.next());
            if (turn == 0) {
                value += board.scores[y * 19 + x][0];
            } else {
                value -= board.scores[y * 19 + x][1];
            }
            board.placeStone(Place{ .x = x, .y = y }, @enumFromInt(turn));
        }
    }
}

test "topPlaces" {
    var board = Board(19, 6, 8).init(std.testing.allocator);
    defer board.deinit();
    board.placeStone(try Place.init("j10"), .first);
    board.placeStone(try Place.init("i10"), .second);
    board.placeStone(try Place.init("j9"), .second);
    const places = board.topPlaces(.first);
    for (places) |place| {
        try std.testing.expect(place.score >= 36);
    }
    const places2 = board.topPlaces(.second);
    for (places2) |place| {
        try std.testing.expect(place.score >= 51);
    }
}

test "decision" {
    var board = Board(19, 6, 8).init(std.testing.allocator);
    defer board.deinit();
    board.placeStone(Place{ .x = 0, .y = 0 }, .first);
    board.placeStone(Place{ .x = 0, .y = 1 }, .first);
    board.placeStone(Place{ .x = 0, .y = 2 }, .first);
    board.placeStone(Place{ .x = 0, .y = 3 }, .first);
    board.placeStone(Place{ .x = 0, .y = 4 }, .first);
    board.placeStone(Place{ .x = 1, .y = 1 }, .first);
    board.placeStone(Place{ .x = 2, .y = 2 }, .first);
    board.placeStone(Place{ .x = 3, .y = 3 }, .first);
    board.placeStone(Place{ .x = 4, .y = 4 }, .first);
    board.placeStone(Place{ .x = 1, .y = 0 }, .first);
    board.placeStone(Place{ .x = 2, .y = 0 }, .first);
    board.placeStone(Place{ .x = 3, .y = 0 }, .first);
    board.placeStone(Place{ .x = 4, .y = 0 }, .first);

    board.placeStone(Place{ .x = 18, .y = 0 }, .second);
    board.placeStone(Place{ .x = 18, .y = 1 }, .second);
    board.placeStone(Place{ .x = 18, .y = 2 }, .second);
    board.placeStone(Place{ .x = 18, .y = 3 }, .second);
    board.placeStone(Place{ .x = 18, .y = 4 }, .second);
    board.placeStone(Place{ .x = 17, .y = 1 }, .second);
    board.placeStone(Place{ .x = 16, .y = 2 }, .second);
    board.placeStone(Place{ .x = 15, .y = 3 }, .second);
    board.placeStone(Place{ .x = 14, .y = 4 }, .second);
    board.placeStone(Place{ .x = 17, .y = 0 }, .second);
    board.placeStone(Place{ .x = 16, .y = 0 }, .second);
    board.placeStone(Place{ .x = 15, .y = 0 }, .second);
    board.placeStone(Place{ .x = 14, .y = 0 }, .second);

    board.placeStone(Place{ .x = 18, .y = 18 }, .first);
    board.placeStone(Place{ .x = 17, .y = 18 }, .first);
    board.placeStone(Place{ .x = 16, .y = 18 }, .first);
    board.placeStone(Place{ .x = 15, .y = 18 }, .first);
    board.placeStone(Place{ .x = 14, .y = 18 }, .first);
    board.placeStone(Place{ .x = 18, .y = 17 }, .first);
    board.placeStone(Place{ .x = 18, .y = 16 }, .first);
    board.placeStone(Place{ .x = 18, .y = 15 }, .first);
    board.placeStone(Place{ .x = 18, .y = 14 }, .first);
    board.placeStone(Place{ .x = 17, .y = 17 }, .first);
    board.placeStone(Place{ .x = 16, .y = 16 }, .first);
    board.placeStone(Place{ .x = 15, .y = 15 }, .first);
    board.placeStone(Place{ .x = 14, .y = 14 }, .first);

    board.placeStone(Place{ .x = 0, .y = 18 }, .second);
    board.placeStone(Place{ .x = 1, .y = 18 }, .second);
    board.placeStone(Place{ .x = 2, .y = 18 }, .second);
    board.placeStone(Place{ .x = 3, .y = 18 }, .second);
    board.placeStone(Place{ .x = 4, .y = 18 }, .second);
    board.placeStone(Place{ .x = 1, .y = 17 }, .second);
    board.placeStone(Place{ .x = 2, .y = 16 }, .second);
    board.placeStone(Place{ .x = 3, .y = 15 }, .second);
    board.placeStone(Place{ .x = 4, .y = 14 }, .second);
    board.placeStone(Place{ .x = 0, .y = 17 }, .second);
    board.placeStone(Place{ .x = 0, .y = 16 }, .second);
    board.placeStone(Place{ .x = 0, .y = 15 }, .second);
    board.placeStone(Place{ .x = 0, .y = 14 }, .second);

    board.print();

    pr("\n 1: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .no_decision);

    board.placeStone(Place{ .x = 0, .y = 5 }, .first);
    pr(" 2: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .first_win);
    board.removeStone();

    board.placeStone(Place{ .x = 5, .y = 5 }, .first);
    pr(" 3: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .first_win);
    board.removeStone();

    board.placeStone(Place{ .x = 5, .y = 0 }, .first);
    pr(" 4: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .first_win);
    board.removeStone();

    board.placeStone(Place{ .x = 18, .y = 5 }, .second);
    pr(" 5: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .second_win);
    board.removeStone();

    board.placeStone(Place{ .x = 13, .y = 5 }, .second);
    pr(" 6: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .second_win);
    board.removeStone();

    board.placeStone(Place{ .x = 13, .y = 0 }, .second);
    pr(" 7: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .second_win);
    board.removeStone();

    board.placeStone(Place{ .x = 13, .y = 18 }, .first);
    pr(" 8: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .first_win);
    board.removeStone();

    board.placeStone(Place{ .x = 18, .y = 13 }, .first);
    pr(" 9: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .first_win);
    board.removeStone();

    board.placeStone(Place{ .x = 13, .y = 13 }, .first);
    pr("10: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .first_win);
    board.removeStone();

    board.placeStone(Place{ .x = 5, .y = 18 }, .second);
    pr("11: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .second_win);
    board.removeStone();

    board.placeStone(Place{ .x = 5, .y = 13 }, .second);
    pr("12: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .second_win);
    board.removeStone();

    board.placeStone(Place{ .x = 0, .y = 13 }, .second);
    pr("13: {any}\n", .{board.decision()});
    try std.testing.expect(board.decision() == .second_win);
    board.removeStone();
}

// Benchmarks
const benchmark = @import("benchmark.zig").benchmark;

fn updateRowBench() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const B = Board(19, 6, 20);
    var board = B.init(allocator);
    defer board.deinit();

    for (0..1_000_000) |_| {
        board.updateRow(18, 18, 6, B.score_table[0]);
        std.mem.doNotOptimizeAway(board);
    }
}

fn placeStoneBench() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const B = Board(19, 6, 20);
    var board = B.init(allocator);
    defer board.deinit();

    var s: f32 = 0;
    for (0..1_000_000) |_| {
        board.placeStone(Place{ .x = 9, .y = 9 }, .first);
        s += board.maxScore(.first);
        board.removeStone();
        std.mem.doNotOptimizeAway(s);
    }
}

fn topPlacesBench() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const B = Board(19, 6, 20);
    var board = B.init(allocator);
    defer board.deinit();

    for (0..1_000_000) |_| {
        const places = board.topPlaces(.first);
        std.mem.doNotOptimizeAway(places);
    }
}

pub fn main() !void {
    pr("updateRow:  {d:.3} µsec\n", .{benchmark(updateRowBench)});
    pr("placeStone: {d:.3} µsec\n", .{benchmark(placeStoneBench)});
    pr("topPlaces:  {d:.3} µsec\n", .{benchmark(topPlacesBench)});
}
