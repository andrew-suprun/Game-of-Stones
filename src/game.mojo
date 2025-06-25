trait TGame(Copyable, Defaultable, Writable):
    alias Move: TMove

    fn moves(self) -> List[Self.Move]:
        ...

    fn play_move(mut self, move: Self.Move):
        ...

    fn decision(self) -> StaticString:
        ...

trait TMove(Copyable, Movable, Defaultable, Stringable, Representable, Writable):

    fn __init__(out self, text: String) raises:
        ...

    fn score(self) -> Score:
        ...

    fn set_score(mut self, score: Score):
        ...

from utils.numerics import FPUtils, inf, neg_inf, nan, isfinite, isinf, isnan

@fieldwise_init("implicit")
@register_passable("trivial")
struct Score(Copyable, Comparable, Defaultable, Stringable, Writable):
    var _value: Float32

    @staticmethod
    fn win() -> Score:
        return Score(inf[DType.float32]())

    @staticmethod
    fn loss() -> Score:
        return Score(neg_inf[DType.float32]())

    @staticmethod
    fn draw() -> Score:
        return Score(-0.0)

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

    fn max(self, other: Score) -> Score:
        return Score(max(self._value, other._value))

    fn __add__(self, other: Score) -> Score:
        return self._value + other._value

    fn __sub__(self, other: Score) -> Score:
        return self._value - other._value

    fn __iadd__(mut self, other: Score):
        self._value += other._value

    fn __isub__(mut self, other: Score):
        self._value -= other._value

    fn __mul__(self, other: Score) -> Score:
        return self._value * other._value

    fn __eq__(self, other: Score) -> Bool:
        return self._value == other._value

    fn __ne__(self, other: Score) -> Bool:
        return self._value != other._value

    fn __lt__(self, other: Score) -> Bool:
        return self._value < other._value

    fn __le__(self, other: Score) -> Bool:
        return self._value <= other._value

    fn __gt__(self, other: Score) -> Bool:
        return self._value > other._value

    fn __ge__(self, other: Score) -> Bool:
        return self._value >= other._value

    fn __neg__(self) -> Score:
        return Score(-self._value) if self._value != 0 else self

    fn iswin(self) -> Bool:
        return isinf(self._value) and self._value > 0

    fn isloss(self) -> Bool:
        return isinf(self._value) and self._value < 0

    fn isdraw(self) -> Bool:
        return self._value == 0 and FPUtils.get_sign(self._value)

    fn is_decisive(self) -> Bool:
        return isinf(self._value) or self.isdraw()

    fn __str__(self) -> String:
        if self.iswin():
            return "win"
        elif self.isloss():
            return "loss"
        elif self.isdraw():
            return "draw"
        else:
            return String(self._value)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(String(self))

