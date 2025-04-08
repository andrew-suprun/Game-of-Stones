const std = @import("std");
const ArrayList = std.ArrayList;

fn TreeNode(comptime Move: type, comptime Score: type) type {
    return struct {
        move: Move,
        score: Score,
        children: []Self,
        n_sims: i32,

        const Self = TreeNode(Move, Score);

        pub fn init(move: Move, score: Score) Self {
            return .{
                .move = move,
                .score = score,
                .children = &[_]Self{},
                .n_sims = 1,
            };
        }
    };
}

pub fn Tree(comptime Move: type, comptime Score: type) type {
    return struct {
        allocator: std.mem.Allocator,
        root: Node,
        top_moves: ArrayList(Node),

        const Self = @This();
        const Node = TreeNode(Move, Score);

        pub fn init(allocator: std.mem.Allocator) Self {
            return .{
                .allocator = allocator,
                .root = Node.init(Move.dummy(), Score.init(0)),
                .top_moves = ArrayList(Node).init(allocator),
            };
        }

        pub fn expand(self: *Self, game: anytype) bool {
            if (Score.isDecisive(self.root.score)) {
                return true;
            } else {
                self.root.expand(game, self.top_moves);
            }

            if (Score.isDecisive(self.root.score)) {
                return true;
            }

            var undecided: isize = 0;
            for (self.root.children) |child| {
                if (!Score.isDecisive(child.score)) {
                    undecided += 1;
                }
            }
            return undecided == 1;
        }

        pub fn score(self: Self) Score {
            return -self.root.score;
        }

        pub fn bestMove(self: Self) Move {
            return self.root.bestMove();
        }

        fn reset(self: *Self) void {
            self.root = Node.init(Move.dummy(), Score.init(0));
            self.top_moves.clear();
        }
    };
}

const M = @import("connect6.zig").Move;
const S = @import("connect6.zig").Score;

pub fn main() void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    _ = Tree(M, S).init(allocator);
}
