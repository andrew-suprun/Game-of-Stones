from utils.numerics import nan, inf, neg_inf, isnan, isfinite, isinf


@always_inline
fn win() -> Float32:
    return inf[DType.float32]()


@always_inline
fn loss() -> Float32:
    return neg_inf[DType.float32]()


@always_inline
fn draw() -> Float32:
    return nan[DType.float32]()


@always_inline
fn is_decisive(v: Float32) -> Bool:
    return not isfinite(v)


@always_inline
fn is_win(v: Float32) -> Bool:
    return isinf(v) and v > 0


@always_inline
fn is_loss(v: Float32) -> Bool:
    return isinf(v) and v < 0


@always_inline
fn is_draw(v: Float32) -> Bool:
    return isnan(v)
