trait TGame(Defaultable, Stringable, Writable):
    alias Move: TMove

    fn moves(self) -> List[(Move, Score)]:
        ...

    fn best_move(self) -> (Move, Score):
        ...

    fn play_move(mut self, move: Move):
        ...

    fn undo_move(mut self, move: Move):
        ...

    fn decision(self) -> StaticString:
        ...

trait TMove(Copyable, Movable, Defaultable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...

from utils.numerics import FPUtils, inf, neg_inf, isinf

alias Score = Float32

alias win = inf[DType.float32]()
alias draw: Float32 = -0
alias loss = neg_inf[DType.float32]()

fn iswin(score: Score) -> Bool:
    return isinf(score) and score > 0

fn isloss(score: Score) -> Bool:
    return isinf(score) and score < 0

fn isdraw(score: Score) -> Bool:
    return score == 0 and FPUtils.get_sign(score)

fn isdecisive(score: Score) -> Bool:
    return isinf(score) or isdraw(score)

fn score_str(score: Score) -> String:
    if iswin(score):
        return "win"
    if isloss(score):
        return "loss"
    if isdraw(score):
        return "draw"
    return String(score)