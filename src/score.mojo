# TODO: Remove this module

from utils.numerics import inf, neg_inf, isfinite, isinf

@register_passable("trivial")
struct Score(Copyable, Movable, Comparable, Stringable, Writable):
    alias win = Score(inf[DType.float32]())
    alias loss = Score(neg_inf[DType.float32]())
    alias draw = Score(Float32(0.25))

    var _score: Float32

    @implicit
    fn __init__(out self, v: Float32):
        self._score = v

    @implicit
    fn __init__(out self, v: FloatLiteral):
        self._score = v

    @implicit
    fn __init__(out self, v: IntLiteral):
        self._score = v

    @always_inline
    fn score(self) -> Float32:
        return self._score if not self.is_draw() else 0

    @always_inline
    fn is_win(self) -> Bool:
        return isinf(self._score) and self._score > 0

    @always_inline
    fn is_loss(self) -> Bool:
        return isinf(self._score) and self._score < 0

    @always_inline
    fn is_draw(self) -> Bool:
        return self._score == 0.25

    @always_inline
    fn is_decisive(self) -> Bool:
        return not isfinite(self._score) or self.is_draw()

    @always_inline
    fn negate(self) -> Score:
        return Score(-self._score)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self._score == other._score

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return self._score != other._score

    @always_inline
    fn __lt__(self: Self, other: Self) -> Bool:
        return self._score < other._score

    @always_inline
    fn __le__(self: Self, other: Self) -> Bool:
        return self._score <= other._score

    @always_inline
    fn __gt__(self: Self, other: Self) -> Bool:
        return self._score > other._score

    @always_inline
    fn __ge__(self: Self, other: Self) -> Bool:
        return self._score >= other._score

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self._score)


def main():
    var s: Score = 5
    print(s._score)
    var t = s.negate()
    var u = Score.win
    var v = u.negate()
    print(s, t, u, v, s < t, s > t, s == t.negate())