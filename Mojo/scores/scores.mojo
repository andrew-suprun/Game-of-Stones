from utils.numerics import nan, inf, neg_inf, isnan, isfinite, isinf

alias Score = Float32
alias win = inf[DType.float32]()
alias loss = neg_inf[DType.float32]()
alias draw = nan[DType.float32]()


@always_inline
fn is_decisive(v: Score) -> Bool:
    return not isfinite(v)


@always_inline
fn is_win(v: Score) -> Bool:
    return isinf(v) and v > 0


@always_inline
fn is_loss(v: Score) -> Bool:
    return isinf(v) and v < 0


@always_inline
fn is_draw(v: Score) -> Bool:
    return isnan(v)
