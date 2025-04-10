const std = @import("std");

const tree = @import("tree.zig");
const Connect6 = @import("connect6.zig").Connect6;
const C6Move = @import("connect6.zig").Move;

test "connect6-tree" {
    const C6 = Connect6(19, 20, 10);
    var c6 = C6.init(std.testing.allocator);
    defer c6.deinit();
    c6.playMove(try C6Move.init("j10"));
    c6.playMove(try C6Move.init("i9-i10"));
    var c6_tree = tree.Tree(C6Move, 30).init(std.testing.allocator);
    defer c6_tree.deinit();

    for (0..1000) |_| {
        _ = c6_tree.expand(&c6);
    }
    try std.testing.expect(c6_tree.current_score() == -2);
}

// Benchmark
const benchmark = @import("benchmark.zig").benchmark;

fn c6ExpandBench() void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    const C6 = Connect6(19, 60, 32);
    var c6 = C6.init(allocator);
    defer c6.deinit();
    c6.playMove(C6Move.init("j10") catch unreachable);
    c6.playMove(C6Move.init("i9-i10") catch unreachable);
    var c6_tree = tree.Tree(C6Move, 20).init(allocator);
    defer c6_tree.deinit();

    for (0..1000) |_| {
        _ = c6_tree.expand(&c6);
    }
    const score = c6_tree.current_score();
    std.mem.doNotOptimizeAway(score);
}

pub fn main() void {
    std.debug.print("c6Expand: {d:.3} msec\n", .{benchmark(c6ExpandBench)});
}
