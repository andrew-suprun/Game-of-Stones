const std = @import("std");
const tree = @import("tree.zig");

const Gomoku = @import("gomoku.zig").Gomoku;
const GMove = @import("gomoku.zig").Move;

test "gomoku-tree" {
    const G = Gomoku(19, 10);
    var gomoku = G.init(std.testing.allocator);
    defer gomoku.deinit();
    gomoku.playMove(try GMove.init("j10"));
    gomoku.playMove(try GMove.init("i9"));
    var gomoku_tree = tree.Tree(GMove, 30).init(std.testing.allocator);
    defer gomoku_tree.deinit();

    for (0..1000) |_| {
        _ = gomoku_tree.expand(&gomoku);
    }
    std.debug.print("r = {d}\n", .{gomoku_tree.current_score()});
    try std.testing.expect(gomoku_tree.current_score() == 40);
}

// Benchmark
const benchmark = @import("benchmark.zig").benchmark;

fn gomokuExpandBench() void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    const G = Gomoku(19, 10);
    var gomoku = G.init(allocator);
    defer gomoku.deinit();
    gomoku.playMove(GMove.init("j10") catch unreachable);
    gomoku.playMove(GMove.init("i9") catch unreachable);
    var gomoku_tree = tree.Tree(GMove, 30).init(allocator);
    defer gomoku_tree.deinit();

    for (0..1000) |_| {
        _ = gomoku_tree.expand(&gomoku);
    }
    const score = gomoku_tree.current_score();
    std.mem.doNotOptimizeAway(score);
}

pub fn main() void {
    std.debug.print("gomokuExpand: {d:.5} msec\n", .{benchmark(gomokuExpandBench)});
}
