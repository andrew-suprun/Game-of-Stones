const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const game = @import("game.zig");
const score = @import("score.zig");
const Player = game.Player;
const Decision = game.Decision;
const board = @import("board.zig");
const Heap = @import("heap.zig").Heap;

pub const Score = score.Score;

pub fn Gomoku(comptime size: comptime_int, comptime max_moves: comptime_int) type {
    return struct {
        board: Board,
        turn: Player = .first,
        heap: Heap(MoveScore, max_moves, less) = .{},

        const Self = @This();
        const Board = board.Board(size, 5, max_moves);
        const MoveScore = score.MoveScore(Move);

        const Move = board.Place;

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
            return "gomoku";
        }

        pub fn playMove(self: *Self, move: Move) void {
            self.board.placeStone(move, self.turn);
            self.turn = opponent(self.turn);
        }

        pub fn undoMove(self: *Self) void {
            self.board.removeStone();
            self.turn = opponent(self.turn);
        }

        pub fn topMoves(self: *Self) []MoveScore {
            self.heap.clear();
            const top_places = if (self.turn == .first) self.board.topPlaces(.first) else self.board.topPlaces(.second);

            if (top_places.len == 0) {
                self.heap.add(MoveScore{ .move = .{ .x = 0, .y = 0 }, .score = score.draw });
                return self.heap.items();
            }
            const turn_idx: usize = @intCast(@intFromEnum(self.turn));
            for (top_places) |place| {
                const place_score = self.board.getScores(place.place)[turn_idx];
                if (place_score == score.win) {
                    self.heap.clear();
                    self.heap.add(MoveScore{ .move = place.place, .score = score.win });
                    return self.heap.items();
                } else if (place_score == 0) {
                    self.heap.add(MoveScore{ .move = place.place, .score = score.draw });
                } else {
                    self.board.placeStone(place.place, self.turn);
                    const opp_score = self.board.maxScore(opponent(self.turn));
                    const coeff: score.Score = @floatFromInt(1 - 2 * turn_idx);
                    const move_score = coeff * self.board.score - opp_score / 2;
                    self.board.removeStone();
                    self.heap.add(MoveScore{ .move = place.place, .score = move_score });
                }
            }

            return self.heap.items();
        }

        pub fn decision(self: Self) Decision {
            return self.board.decision();
        }

        pub fn print(self: Self) void {
            self.board.print();
        }

        pub fn printScores(self: Self) void {
            self.board.printScores();
        }

        fn opponent(player: Player) Player {
            return if (player == .first) .second else .first;
        }
    };
}

test "topMoves" {
    const GomokuGame = Gomoku(19, 10);
    var gomoku = GomokuGame.init(std.testing.allocator);
    defer gomoku.deinit();
    gomoku.playMove(board.Place{ .x = 9, .y = 9 });
    gomoku.print();
    gomoku.printScores();
}

const benchmark = @import("benchmark.zig").benchmark;

fn c6TopMovesBench() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const G = Gomoku(19, 32);
    var gomoku = G.init(allocator);
    defer gomoku.deinit();
    gomoku.playMove(G.Move{ .x = 9, .y = 9 });
    gomoku.playMove(G.Move{ .x = 8, .y = 8 });
    for (0..1000) |_| {
        _ = gomoku.topMoves();
    }
}

pub fn main() !void {
    std.debug.print("gomokuTopMoves: {d:.3} msec\n", .{benchmark(c6TopMovesBench)});
}
