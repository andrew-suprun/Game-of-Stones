const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;

const score = @import("score.zig");

fn run(comptime Game: type, comptime exp_factor: score.Score, allocator: Allocator) !void {
    var args = std.process.args();
    defer args.deinit();
    _ = args.next();
    const arg = args.next() orelse "";
    print("arg: {s}\n", .{arg});
    const wd = std.fs.cwd();
    var buf: [1024]u8 = undefined;
    const path = try wd.realpath(".", &buf);
    print("wd: {s}\n", .{path});
    const log_file = if (arg.len > 0) try wd.createFile(arg, .{}) else null;
    defer {
        if (log_file) |log| {
            log.close();
        }
    }
    const log_writer = if (log_file) |log| log.writer() else null;
    const reader = std.io.getStdIn().reader();
    const writer = std.io.getStdOut().writer();
    _ = writer;

    const game = Game.init(allocator);
    const game_tree = tree.Tree(Game, exp_factor);

    while (true) {
        var line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse "";
        line = std.mem.trim(u8, line, " ");
        if (line.len == 0) continue;
        if (log_writer) |logger| {
            try logger.print("got {s}\n", .{line});
        }
        // var terms = line.split(" ")
        // if terms[0] == "game-name":
        //     print("game-name", game.name())
        // elif terms[0] == "move":
        //     var move = Move(terms[1])
        //     game.play_move(move)
        //     tree.reset()
        //     if log:
        //         print(game, file=log_file)
        // elif terms[0] == "undo":
        //     game.undo_move()
        //     tree.reset()
        //     if log:
        //         print(game, file=log_file)
        // elif terms[0] == "respond":
        //     var deadline = perf_counter_ns() + Int(terms[1]) * 1_000_000
        //     var sims = 0
        //     while perf_counter_ns() < deadline:
        //         if tree.expand(game):
        //             if log:
        //                 print("DONE", file=log_file)
        //             break
        //         sims += 1
        //     var move = tree.best_move()
        //     game.play_move(move)
        //     tree.reset()
        //     print("move", move, game.decision(), sims)
        //     if log:
        //         print("move", move, file=log_file)
        //         print("sims", sims, file=log_file)
        //         print(game, file=log_file)
        // elif terms[0] == "stop":
        //     if log:
        //         log_file.close()
        //     return
        // else:
        //     if log:
        //         print("unknown", line, file=log_file)

    }

    _ = game;
    _ = game_tree;
}

const tree = @import("tree.zig");
const Connect6 = @import("connect6.zig").Connect6;
const C6Move = @import("connect6.zig").Move;

pub fn main() !void {
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

    try run(C6, 30, allocator);
}
