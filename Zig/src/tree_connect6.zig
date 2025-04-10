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
    std.debug.assert(c6_tree.current_score() == -2);
}

pub fn main() void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    _ = tree.Tree(C6Move).init(allocator);
}
