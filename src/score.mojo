from std.utils.numerics import FPUtils, isinf, nan, isnan

comptime Score = Float32
comptime Win = Score.MAX
comptime Loss = Score.MIN
comptime Draw = Score(-0.0)
comptime NoScore = nan[Score.dtype]()

def is_win(score: Score) -> Bool:
    return isinf(score) and score > 0

def is_loss(score: Score) -> Bool:
    return isinf(score) and score < 0

def is_draw(score: Score) -> Bool:
    return score == 0 and FPUtils.get_sign(score)

def is_decisive(score: Score) -> Bool:
    return isinf(score) or is_draw(score)

def is_set(score: Score) -> Bool:
    return not isnan(score)

def neg(score: Score) -> Score:
    return Draw if is_draw(score) else 0 if score == 0 else -score

def score_str(score: Score) -> String:
    if not is_set(score):
        return "no-score"
    elif is_win(score):
        return "win"
    elif is_loss(score):
        return "loss"
    elif is_draw(score):
        return "draw"
    else:
        return String(score)