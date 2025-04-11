const std = @import("std");

const tree = @import("tree.zig");
const run = @import("engine.zig").run;
const Gomoku = @import("gomoku.zig").Gomoku;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    const Game = Gomoku(19, 12);
    var game = Game.init(allocator);
    defer game.deinit();
    var game_tree = tree.Tree(Game.Move, 20).init(allocator);
    defer game_tree.deinit();

    try run(Game, 30, allocator);
}
