const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const game = @import("game.zig");
const score = @import("score.zig");
const Player = game.Player;
const Decision = game.Decision;
const board = @import("board.zig");
const Heap = @import("heap.zig").Heap;

pub fn Connect6(comptime size: comptime_int, comptime max_moves: comptime_int, comptime max_places: comptime_int) type {
    return struct {
        board: Board,
        turn: Player = .first,
        heap: Heap(score.MoveScore(Move), max_moves, less) = .{},

        const Self = @This();
        const Board = board.Board(size, 6, max_places);
        const MoveScore = score.MoveScore(Move);
        pub const Move = struct {
            place1: board.Place,
            place2: board.Place,

            pub fn init(text: []const u8) !Move {
                var it = std.mem.tokenizeScalar(u8, text, '-');
                const token1 = it.next() orelse return error.ParseError;
                const token2 = it.next() orelse token1;
                const place1 = try board.Place.init(token1);
                const place2 = try board.Place.init(token2);
                return .{ .place1 = place1, .place2 = place2 };
            }

            pub fn dummy() Move {
                return Move{ .place1 = board.Place.dummy(), .place2 = board.Place.dummy() };
            }

            pub fn str(self: Move, buf: []u8) []u8 {
                std.debug.assert(buf.len >= 7);
                const p1 = self.place1.str(buf);
                if (self.place1.eql(self.place2)) {
                    return p1;
                }
                buf[p1.len] = '-';
                const p2 = self.place2.str(buf[p1.len + 1 ..]);
                return buf[0 .. p1.len + p2.len + 1];
            }

            pub fn eql(a: Move, b: Move) bool {
                return a.place1.eql(b.place1) and a.place2.eql(b.place2) or
                    a.place1.eql(b.place2) and a.place2.eql(b.place1);
            }
        };

        fn less(a: MoveScore, b: MoveScore) bool {
            return a.score < b.score;
        }

        pub fn init(allocator: Allocator) Self {
            return .{ .board = Board.init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.board.deinit();
        }

        pub fn name(_: Self) []const u8 {
            return "connect6";
        }

        pub fn playMove(self: *Self, move: Move) void {
            self.board.placeStone(move.place1, self.turn);
            if (move.place1.x != move.place2.x or move.place1.y != move.place2.y) { // TODO use Move.eql()
                self.board.placeStone(move.place2, self.turn);
            }
            self.turn = opponent(self.turn);
        }

        pub fn undoMove(self: *Self) void {
            self.board.removeStone();
            self.board.removeStone();
            self.turn = opponent(self.turn);
        }

        pub fn topMoves(self: *Self) []MoveScore {
            self.heap.clear();
            const top_places = if (self.turn == .first) self.board.topPlaces(.first) else self.board.topPlaces(.second);

            if (top_places.len < 2) {
                if (top_places.len == 1) {
                    const top_place = top_places[0];
                    self.heap.add(MoveScore{ .move = Move{ .place1 = top_place.place, .place2 = top_place.place }, .score = score.draw });
                } else {
                    self.heap.add(MoveScore{ .move = Move{ .place1 = .{ .x = 0, .y = 0 }, .place2 = .{ .x = 0, .y = 0 } }, .score = score.draw });
                }
                return self.heap.items();
            }
            const turn_idx: usize = @intCast(@intFromEnum(self.turn));
            for (0..top_places.len - 1) |i| {
                const place1 = top_places[i];
                const score1 = self.board.getScores(place1.place)[turn_idx];
                if (score1 == score.win) {
                    self.heap.clear();
                    self.heap.add(MoveScore{ .move = Move{ .place1 = place1.place, .place2 = place1.place }, .score = score.win });
                    return self.heap.items();
                }

                self.board.placeStone(place1.place, self.turn);

                for (i + 1..top_places.len) |j| {
                    const place2 = top_places[j];
                    const score2 = self.board.getScores(place2.place)[turn_idx];

                    if (score2 == score.win) {
                        self.heap.clear();
                        self.heap.add(MoveScore{ .move = Move{ .place1 = place1.place, .place2 = place2.place }, .score = score.win });
                        self.board.removeStone();
                        return self.heap.items();
                    } else if (score1 + score2 == 0) {
                        self.heap.add(MoveScore{ .move = Move{ .place1 = place1.place, .place2 = place2.place }, .score = score.draw });
                    } else {
                        self.board.placeStone(place2.place, self.turn);
                        const opp_score = self.board.maxScore(opponent(self.turn));
                        const coeff: score.Score = 1 - 2 * @as(score.Score, @floatFromInt(turn_idx));
                        const move_score = coeff * self.board.score - opp_score;
                        self.board.removeStone();
                        self.heap.add(MoveScore{ .move = Move{ .place1 = place1.place, .place2 = place2.place }, .score = move_score });
                    }
                }
                self.board.removeStone();
            }

            return self.heap.items();
        }

        pub fn decision(self: Self) Decision {
            return self.board.decision();
        }

        pub fn str(self: Self, buf: []u8) []u8 {
            return self.board.str(buf);
        }

        pub fn scoresStr(self: Self, buf: []u8) []u8 {
            self.board.scoresStr(buf);
        }

        fn opponent(player: Player) Player {
            return if (player == .first) .second else .first;
        }
    };
}

test "parsePlace" {
    const C6 = Connect6(19, 20, 10);
    var move = try C6.Move.init("s19");
    try std.testing.expect(move.place1.x == 18);
    try std.testing.expect(move.place2.y == 18);
    var buf: [7]u8 = undefined;
    var str = move.str(buf[0..]);
    try std.testing.expect(std.mem.eql(u8, "s19", str));
    move = try C6.Move.init("a1-s19");
    str = move.str(buf[0..]);
    try std.testing.expect(move.eql(C6.Move{ .place1 = .{ .x = 0, .y = 0 }, .place2 = .{ .x = 18, .y = 18 } }));
    try std.testing.expect(std.mem.eql(u8, "a1-s19", str));
}

test "topMoves" {
    const C6 = Connect6(19, 20, 10);
    var c6 = C6.init(std.testing.allocator);
    defer c6.deinit();
    c6.playMove(C6.Move{ .place1 = board.Place{ .x = 9, .y = 9 }, .place2 = board.Place{ .x = 9, .y = 9 } });
    c6.print();
    c6.printScores();
}

// Benchmark
const benchmark = @import("benchmark.zig").benchmark;

fn c6TopMovesBench() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const C6 = Connect6(19, 60, 32);
    var c6 = C6.init(allocator);
    defer c6.deinit();
    c6.playMove(C6.Move{ .place1 = board.Place{ .x = 9, .y = 9 }, .place2 = board.Place{ .x = 9, .y = 9 } });
    c6.playMove(C6.Move{ .place1 = board.Place{ .x = 9, .y = 8 }, .place2 = board.Place{ .x = 9, .y = 10 } });
    for (0..1000) |_| {
        _ = c6.topMoves();
    }
}

pub fn main() !void {
    std.debug.print("connect6TopMoves: {d:.3} msec\n", .{benchmark(c6TopMovesBench)});
}
