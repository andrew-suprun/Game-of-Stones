from utils.numerics import nan, isinf, isnan

alias Score = Float32
alias win = Score.MAX
alias loss = Score.MIN
alias draw = nan[DType.float32]()

fn is_win(score: Score) -> Bool:
    return isinf(score) and score > 0

fn is_loss(score: Score) -> Bool:
    return isinf(score) and score < 0

fn is_draw(score: Score) -> Bool:
    return isnan(score)

fn is_decisive(score: Score) -> Bool:
    return isinf(score) or isnan(score)

fn str_score(score: Score) -> String:
    if is_win(score):
        return "win"
    if is_loss(score):
        return "loss"
    if is_draw(score):
        return "draw"
    return String(score)
