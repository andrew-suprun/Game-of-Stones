const std = @import("std");

pub const Score = f32;

pub const win = std.math.inf(f32);
pub const loss = -std.math.inf(f32);
pub const draw = 0.25;

pub fn isWin(score: Score) bool {
    return std.math.isPositiveInf(score);
}

pub fn isLoss(score: Score) bool {
    return std.math.isNegativeInf(score);
}

pub fn isDraw(score: Score) bool {
    return score == draw;
}

pub fn isDecisive(score: Score) bool {
    return score == draw or std.math.isInf(score);
}

pub fn MoveScore(comptime Move: type) type {
    return struct {
        move: Move,
        score: Score,
    };
}
