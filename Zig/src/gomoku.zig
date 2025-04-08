const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const game = @import("game.zig");
const Player = game.Player;
const Decision = game.Decision;
const board = @import("board.zig");
const Heap = @import("heap.zig").Heap;

pub fn Gomoku(comptime size: comptime_int, comptime max_moves: comptime_int) type {
    return struct {
        board: Board,
        turn: Player = .first,
        heap: Heap(MoveScore, max_moves, less) = .{},

        const Self = @This();
        const Board = board.Board(size, 5, max_moves);

        const Move = board.Place;

        const MoveScore = struct {
            move: Move,
            score: board.Score,
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
            return "gomoku";
        }

        pub fn playMove(self: *Self, move: Move) void {
            self.board.placeStone(move, self.turn);
            self.switchTurn();
        }

        pub fn undoMove(self: *Self) void {
            self.board.removeStone();
            self.switchTurn();
        }

        pub fn topMoves(self: *Self) []MoveScore {
            self.heap.clear();
            const top_places = if (self.turn == .first) self.board.topPlaces(.first) else self.board.topPlaces(.second);

            if (top_places.len == 0) {
                self.heap.add(MoveScore(.{}, .{}), board.draw);
                return self.heap.items();
            }
            for (top_places) |place| {
                const score = self.board.getScores(place.place)[self.turn];
                if (score == board.win) {
                    self.heap.clear();
                    self.heap.add(MoveScore{ .move = place, .score = board.win });
                    return self.heap.items;
                } else if (score == 0) {
                    self.heap.add(MoveScore{ .move = place, .score = board.draw });
                } else {
                    self.board.placeStone(place, self.turn);
                    const opp_score = self.board.maxScore(1 - self.turn);
                    const coeff = 1 - 2 * self.turn;
                    const move_score = coeff * self.board.score - opp_score / 2;
                    self.board.removeStone();
                    self.heap.add(MoveScore{ .move = place, .score = move_score });
                    self.board.removeStone();
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

        fn switchTurn(self: *Self) void {
            self.turn = if (self.turn == .first) .second else .first;
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

pub fn main() void {}
