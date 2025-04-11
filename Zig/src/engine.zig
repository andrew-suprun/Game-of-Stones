const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const eql = std.mem.eql;
const trim = std.mem.trim;

const score = @import("score.zig");

fn run(comptime Game: type, comptime exp_factor: score.Score, allocator: Allocator) !void {
    var args = std.process.args();
    defer args.deinit();

    var buf: [1024]u8 = undefined;
    _ = args.next();
    const arg = args.next() orelse "";
    print("arg: {s}\n", .{arg});
    const wd = std.fs.cwd();
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

    var game = Game.init(allocator);
    var game_tree = tree.Tree(Game.Move, exp_factor).init(allocator);

    while (true) {
        var line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse "";
        line = trim(u8, line, " ");
        if (line.len == 0) continue;
        if (log_writer) |logger| {
            try logger.print("got {s}\n", .{line});
        }
        var terms = std.mem.tokenizeScalar(u8, line, ' ');
        const cmd = terms.next() orelse "";
        if (eql(u8, cmd, "game-name")) {
            print("game-name {s}\n", .{game.name()});
        } else if (eql(u8, cmd, "move")) {
            const move_str = terms.next() orelse "";
            const move = Game.Move.init(move_str) catch {
                print("Error: invalid 'move' command\n", .{});
                continue;
            };
            game.playMove(move);
            game_tree.reset();
            if (log_writer) |log| {
                log.print("here is game board\n", .{}) catch {};
            }
        } else if (eql(u8, cmd, "undo")) {
            game.undoMove();
            game_tree.reset();
            if (log_writer) |log| {
                log.print("here is game board\n", .{}) catch {};
            }
        } else if (eql(u8, cmd, "respond")) {
            const duration_slice = terms.next() orelse "";
            const duration = std.fmt.parseInt(isize, duration_slice, 10) catch {
                print("Error: invalid 'respond' command\n", .{});
                continue;
            };
            const deadline = std.time.milliTimestamp() + duration;
            var sims: isize = 0;
            while (std.time.milliTimestamp() < deadline) {
                if (game_tree.expand(&game)) {
                    if (log_writer) |log| {
                        log.print("DONE\n", .{}) catch {};
                    }
                    break;
                }
                sims += 1;
            }
            const move = game_tree.bestMove();
            game.playMove(move);
            game_tree.reset();
            var move_buf: [64]u8 = undefined;
            const move_str = move.str(&move_buf);
            print("move {s} {s} {d}\n", .{ move_str, game.decision().str(), sims });
        } else if (eql(u8, cmd, "stop")) {
            return;
        } else {
            if (log_writer) |log| {
                log.print("unknown {s}\n", .{line}) catch {};
            }
        }
    }
}

const tree = @import("tree.zig");
const Connect6 = @import("connect6.zig").Connect6;

pub fn main() !void {
    var da = std.heap.DebugAllocator(.{}).init;
    defer _ = da.deinit();
    const allocator = da.allocator();

    const C6 = Connect6(19, 60, 32);
    var c6 = C6.init(allocator);
    defer c6.deinit();
    c6.playMove(C6.Move.init("j10") catch unreachable);
    c6.playMove(C6.Move.init("i9-i10") catch unreachable);
    var c6_tree = tree.Tree(C6.Move, 20).init(allocator);
    defer c6_tree.deinit();

    try run(C6, 30, allocator);
}
