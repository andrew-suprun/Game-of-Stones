from utils.numerics import inf, neg_inf, nan, isfinite, isinf, isnan
import math

from game import TScore


@fieldwise_init("implicit")
@register_passable("trivial")
struct Score(TScore):
    var _value: Float32

    @staticmethod
    fn win() -> Score:
        return Score(inf[DType.float32]())

    @staticmethod
    fn loss() -> Score:
        return Score(neg_inf[DType.float32]())

    @staticmethod
    fn draw() -> Score:
        return Score(0.5)

    fn __init__(out self):
        self._value = 0

    @implicit
    fn __init__(out self, value: FloatLiteral):
        self._value = Float32(value)

    @implicit
    fn __init__(out self, value: IntLiteral):
        self._value = value

    fn value(self) -> Float32:
        return self._value

    fn min(self, other: Score) -> Score:
        return Score(min(self._value, other._value))

    fn __lt__(self, other: Score) -> Bool:
        return self._value < other._value

    fn __neg__(self) -> Score:
        return Score(-self._value)

    fn is_win(self) -> Bool:
        return isinf(self._value) and self._value > 0

    fn is_loss(self) -> Bool:
        return isinf(self._value) and self._value < 0

    fn is_draw(self) -> Bool:
        return self._value == 0.5

    fn is_decisive(self) -> Bool:
        return isinf(self._value) or self.is_draw()

    fn __str__(self) -> String:
        if self.is_win():
            return "win"
        elif self.is_loss():
            return "loss"
        elif self.is_draw():
            return "draw"
        else:
            return String(self._value)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(String(self))



def main():
    var s: Score = 5
    var t = -s
    var u = Score.win()
    var v = -u
    var x = Score.draw()
    print(t)
    print(s, t, u, v, x, s < x, t < x)
