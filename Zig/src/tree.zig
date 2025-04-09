const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;

const score = @import("score.zig");

pub fn Tree(comptime Move: type, comptime C: score.Score) type {
    return struct {
        allocator: Allocator,
        root: Node,

        const Self = @This();
        const Node = TreeNode(Move, C);
        const MoveScore = score.MoveScore(Move);

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .root = Node.init(Move.dummy(), 0),
            };
        }

        pub fn deinit(self: *Self) void {
            self.root.deinit(self.allocator);
        }

        pub fn expand(self: *Self, game: anytype) bool {
            if (score.isDecisive(self.root.score)) {
                return true;
            } else {
                self.root.expand(game, self.allocator);
            }

            if (score.isDecisive(self.root.score)) {
                return true;
            }

            var undecided: isize = 0;
            for (self.root.children) |child| {
                if (!score.isDecisive(child.score)) {
                    undecided += 1;
                }
            }
            return undecided == 1;
        }

        pub fn current_score(self: Self) score.Score {
            return -self.root.score;
        }

        pub fn bestMove(self: Self) Move {
            return self.root.bestMove();
        }

        fn reset(self: *Self) void {
            self.root = Node.init(Move.dummy(), score.Score.init(0));
        }

        pub fn printTree(self: Self) void {
            self.root.printTree(0);
        }
    };
}

fn TreeNode(comptime Move: type, comptime C: score.Score) type {
    return struct {
        move: Move,
        score: score.Score,
        children: []Self,
        n_sims: i32,

        const Self = TreeNode(Move, C);
        const MoveScore = score.MoveScore(Move);

        pub fn init(move: Move, move_score: score.Score) Self {
            return .{
                .move = move,
                .score = move_score,
                .children = &[_]Self{},
                .n_sims = 1,
            };
        }

        pub fn deinit(self: *Self, allocator: Allocator) void {
            for (self.children) |*child| {
                child.deinit(allocator);
            }
            allocator.free(self.children);
        }

        pub fn expand(self: *Self, g: anytype, allocator: Allocator) void {
            if (self.children.len == 0) {
                const top_moves = g.topMoves();
                std.debug.assert(top_moves.len > 0);

                self.children = allocator.alloc(Self, top_moves.len) catch unreachable;
                for (top_moves, 0..) |move, i| {
                    self.children[i] = Self.init(move.move, move.score);
                }
            } else {
                const n_sims = self.n_sims;
                const log_parent_sims = std.math.log2(@as(score.Score, @floatFromInt(n_sims)));
                var selected_child = &self.children[0];
                var maxV = score.loss;
                for (self.children) |*child| {
                    if (score.isDecisive(child.score)) {
                        continue;
                    }
                    const v = child.score + C * std.math.sqrt(log_parent_sims / @as(score.Score, @floatFromInt(child.n_sims)));
                    if (v > maxV) {
                        maxV = v;
                        selected_child = child;
                    }
                }
                g.playMove(selected_child.move);
                selected_child.expand(g, allocator);
                g.undoMove();
            }

            self.n_sims = 0;
            self.score = score.win;
            var has_draw = false;
            var all_draws = true;
            for (self.children) |child| {
                if (score.isWin(child.score)) {
                    self.score = -child.score;
                    return;
                } else if (score.isDraw(child.score)) {
                    has_draw = true;
                    continue;
                }
                all_draws = false;
                if (score.isLoss(child.score)) {
                    continue;
                }
                self.n_sims += child.n_sims;
                if (self.score >= -child.score) {
                    self.score = -child.score;
                }
            }
            if (all_draws) {
                self.score = score.draw;
            } else if (has_draw and self.score > 0) {
                self.score = 0;
            }
        }

        fn bestMove(self: Self) Move {
            std.debug.assert(self.children.len > 0);
            var bestChild = &self.children[0];
            for (self.children) |child| {
                if (bestChild.score < child.score) {
                    bestChild = child;
                } else if (score.isLoss(bestChild.score) and bestChild.n_sims < child.n_sims) {
                    bestChild = child;
                }
            }
            return bestChild.move;
        }

        pub fn printNode(self: Self) void {
            var buf: [32]u8 = undefined;
            const move = self.move.str(&buf);
            print("{s}: v: {d} s: {d}\n", .{ move, self.score, self.n_sims });
        }

        pub fn printTree(self: Self, depth: usize) void {
            for (0..depth) |_| {
                print("|   ", .{});
            }
            self.printNode();
            for (self.children) |child| {
                child.printTree(depth + 1);
            }
        }
    };
}
