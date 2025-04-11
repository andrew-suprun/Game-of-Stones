const std = @import("std");

const tree = @import("tree.zig");
const run = @import("engine.zig").run;
const Connect6 = @import("connect6.zig").Connect6;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    const Game = Connect6(19, 32, 16);
    var game = Game.init(allocator);
    defer game.deinit();
    var game_tree = tree.Tree(Game.Move, 30).init(allocator);
    defer game_tree.deinit();

    try run(Game, 30, allocator);
}
