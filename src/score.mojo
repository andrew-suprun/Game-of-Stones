from utils.numerics import inf, neg_inf, nan, isfinite, isinf, isnan

@fieldwise_init("implicit")
@register_passable("trivial")
struct Score(Copyable, LessThanComparable, Stringable, Writable):
    alias win = Score(inf[DType.float32]())
    alias loss = Score(neg_inf[DType.float32]())
    alias draw = Score(nan[DType.float32]())

    var score: Float32

    @implicit
    fn __init__(out self, score: FloatLiteral):
        self.score = score

    @implicit
    fn __init__(out self, score: IntLiteral):
        self.score = score

    fn __lt__(self, other: Self) -> Bool:
        return self.score < other.score

    fn __neg__(self) -> Self:
        return -self.score

    fn is_decisive(self) -> Bool:
        return not isfinite(self.score) or self.is_draw()

    fn is_win(self) -> Bool:
        return isinf(self.score) and self.score > 0

    fn is_loss(self) -> Bool:
        return isinf(self.score) and self.score < 0

    fn is_draw(self) -> Bool:
        return isnan(self.score)

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self.is_win():
            writer.write("win")
        elif self.is_loss():
            writer.write("loss")
        elif self.is_draw():
            writer.write("draw")
        else:
            writer.write(self.score)


def main():
    var s: Score = 5
    var t = -s
    var u = Score.win
    var v = -u
    var x = Score.draw
    print(s, t, u, v, x, s < t)
