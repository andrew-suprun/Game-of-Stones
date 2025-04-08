const std = @import("std");

pub fn benchmark(func: fn () void) f64 {
    var minDur: u64 = std.math.maxInt(u64);
    var timer = std.time.Timer.start() catch unreachable;
    for (0..5) |_| {
        func();
        const dur = timer.lap();
        if (minDur > dur) {
            minDur = dur;
        }
    }
    return @as(f64, @floatFromInt(minDur)) / 1_000_000_000;
}
