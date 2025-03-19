from utils.numerics import inf, neg_inf, isfinite, isinf

alias Score = Float32
alias Scores = SIMD[DType.float32, 2]
alias win = inf[DType.float32]()
alias loss = neg_inf[DType.float32]()
alias draw = Score(0.25)


@always_inline
fn is_decisive(v: Score, out result: Bool):
    return not isfinite(v) or is_draw(v)


@always_inline
fn is_win(v: Score, out result: Bool):
    return isinf(v) and v > 0


@always_inline
fn is_loss(v: Score, out result: Bool):
    return isinf(v) and v < 0


@always_inline
fn is_draw(v: Score, out result: Bool):
    return v == draw
