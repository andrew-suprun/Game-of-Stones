const std = @import("std");
const ArrayList = std.ArrayList;

const score = @import("score.zig");

pub fn Tree(comptime Move: type) type {
    return struct {
        allocator: std.mem.Allocator,
        root: Node,
        top_moves: ArrayList(Node),

        const Self = @This();
        const Node = TreeNode(Move);
        const MoveScore = score.MoveScore(Move);

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .root = Node.init(Move.dummy(), 0),
                .top_moves = ArrayList(Node).init(allocator),
            };
        }

        pub fn expand(self: *Self, game: anytype) bool {
            if (score.isDecisive(self.root.score)) {
                return true;
            } else {
                self.root.expand(game, self.top_moves);
            }

            if (score.Score.isDecisive(self.root.score)) {
                return true;
            }

            var undecided: isize = 0;
            for (self.root.children) |child| {
                if (!score.Score.isDecisive(child.score)) {
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
            self.top_moves.clear();
        }
    };
}

fn TreeNode(comptime Move: type) type {
    return struct {
        move: Move,
        score: score.Score,
        children: []Self,
        n_sims: i32,

        const Self = TreeNode(Move);
        const MoveScore = score.MoveScore(Move);

        pub fn init(move: Move, move_score: score.Score) Self {
            return .{
                .move = move,
                .score = move_score,
                .children = &[_]Self{},
                .n_sims = 1,
            };
        }

        pub fn expand(self: *Self, g: anytype, top_moves: *ArrayList[MoveScore]) void {
            if (self.children.len == 0) {
                g.topMoves(top_moves);
                std.debug.assert(top_moves.len > 0);

                self.children.ensureTotalCapacityPrecise(top_moves.len);
                for (top_moves) |move| {
                    self.children.append(Self.init(move));
                }
            } else {
                const n_sims = self.n_sims;
                const log_parent_sims = std.math.log2(score.Score(n_sims));
                var selected_child = &self.children[0];
                var maxV = MoveScore.Score.loss;
                for (self.children) |child| {
                    if (child.score.is_decisive()) {
                        continue;
                    }
                    const v = child.score + self.c * std.math.sqrt(log_parent_sims / child.n_sims);
                    if (v > maxV) {
                        maxV = v;
                        selected_child = child;
                    }
                }
                const move = selected_child.moveScore;
                g.playMove(move.move);
                selected_child.expand(g, top_moves);
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
    };
}

const C6Move = @import("connect6.zig").Move;

pub fn main() void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    _ = Tree(C6Move).init(allocator);
}
