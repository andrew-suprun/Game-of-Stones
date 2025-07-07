from utils.numerics import inf, neg_inf, isinf, FPUtils

alias Score = Float32
alias loss = neg_inf[DType.float32]()
alias draw: Score = -0.0
alias win = inf[DType.float32]()

fn invert(score: Score) -> Score:
    return -score if score != 0 else 0

fn iswin(score: Score) -> Bool:
    return isinf(score) and score > 0

fn isloss(score: Score) -> Bool:
    return isinf(score) and score < 0

fn isdraw(score: Score) -> Bool:
    return score == 0 and FPUtils.get_sign(score)

fn isdecisive(score: Score) -> Bool:
    return isinf(score) or isdraw(score)

fn str(score: Score) -> String:
    if iswin(score):
        return "win"
    if isloss(score):
        return "loss"
    if isdraw(score):
        return "draw"
    return String(score)
