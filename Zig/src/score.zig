const std = @import("std");

pub const Score = f32;

pub const win = std.math.inf(f32);
pub const loss = -std.math.inf(f32);
pub const draw = 0.5;

pub fn init(value: f32) Score {
    return Score{ .value = value };
}

pub fn isWin(score: Score) bool {
    return std.math.isPositiveInf(score.value);
}

pub fn isLoss(score: Score) bool {
    return std.math.isNegativeInf(score.value);
}

pub fn isDraw(score: Score) bool {
    return score.value == 0.5;
}

pub fn isDecisive(score: Score) bool {
    return score.value == 0.5 or std.math.isInf(score.value);
}

pub fn MoveScore(comptime Move: type) type {
    return struct {
        move: Move,
        score: Score,
    };
}
