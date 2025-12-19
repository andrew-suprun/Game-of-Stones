const std = @import("std");

pub const Score = f32;

pub const draw: Score = -0.0;
pub const win: Score = std.math.inf(Score);
pub const loss: Score = -std.math.inf(Score);
pub const no_score: Score = std.math.nan(Score);

pub fn isWin(score: Score) bool {
    return score == win;
}

pub fn isDraw(score: Score) bool {
    return score == 0.0 and @as(i32, @bitCast(score)) < 0;
}

pub fn isLoss(score: Score) bool {
    return score == loss;
}

pub fn isSet(score: Score) bool {
    return score == score;
}

pub fn isDecisive(score: Score) bool {
    return isDraw(score) or std.math.isInf(score);
}

pub fn MoveScore(comptime Move: type) type {
    return struct {
        move: Move,
        score: Score,
    };
}

const assert = std.debug.assert;

test {
    assert(isWin(win));
    assert(!isWin(draw));
    assert(!isWin(0.0));
    assert(!isWin(loss));
    assert(!isWin(no_score));

    assert(!isDraw(win));
    assert(isDraw(draw));
    assert(!isDraw(0.0));
    assert(!isDraw(loss));
    assert(!isDraw(no_score));

    assert(!isLoss(win));
    assert(!isLoss(draw));
    assert(!isLoss(0.0));
    assert(isLoss(loss));
    assert(!isLoss(no_score));

    assert(isSet(win));
    assert(isSet(draw));
    assert(isSet(0.0));
    assert(isSet(loss));
    assert(!isSet(no_score));

    assert(isDecisive(win));
    assert(isDecisive(draw));
    assert(!isDecisive(0.0));
    assert(isDecisive(loss));
    assert(!isDecisive(no_score));

    assert(win > draw);
    assert(draw == 0.0);
    assert(draw > loss);
    assert(no_score != no_score);
}
