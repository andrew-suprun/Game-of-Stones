const std = @import("std");
const print = std.debug.print;
const Allocator = std.mem.Allocator;
const eql = std.mem.eql;
const trim = std.mem.trim;

const score = @import("score.zig");
const tree = @import("tree.zig");

pub fn run(comptime Game: type, comptime exp_factor: score.Score, allocator: Allocator) !void {
    var args = std.process.args();
    defer args.deinit();

    var buf: [8192]u8 = undefined;
    _ = args.next();
    const arg = args.next() orelse "";
    const wd = std.fs.cwd();
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
        const line = try reader.readUntilDelimiterOrEof(&buf, '\n') orelse "";
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
                log.print("{s}\n", .{game.str(&buf)}) catch {};
            }
        } else if (eql(u8, cmd, "undo")) {
            game.undoMove();
            game_tree.reset();
            if (log_writer) |log| {
                log.print("{s}\n", .{game.str(&buf)}) catch {};
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
