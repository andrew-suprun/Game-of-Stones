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

from utils.numerics import FPUtils, inf, neg_inf, isinf

@fieldwise_init("implicit")
@register_passable("trivial")
struct Score(Copyable, Comparable, Defaultable, Stringable, Writable):
    var _value: Float32

    @staticmethod
    @always_inline
    fn win() -> Score:
        return Score(inf[DType.float32]())

    @staticmethod
    @always_inline
    fn loss() -> Score:
        return Score(neg_inf[DType.float32]())

    @staticmethod
    @always_inline
    fn draw() -> Score:
        return Score(-0.0)

    @always_inline
    fn __init__(out self):
        self._value = 0

    @implicit
    @always_inline
    fn __init__(out self, value: FloatLiteral):
        self._value = Float32(value)

    @implicit
    @always_inline
    fn __init__(out self, value: IntLiteral):
        self._value = value

    @always_inline
    fn value(self) -> Float32:
        return self._value

    @always_inline
    fn min(self, other: Score) -> Score:
        return Score(min(self._value, other._value))

    @always_inline
    fn max(self, other: Score) -> Score:
        return Score(max(self._value, other._value))

    @always_inline
    fn __add__(self, other: Score) -> Score:
        return self._value + other._value

    @always_inline
    fn __sub__(self, other: Score) -> Score:
        return self._value - other._value

    @always_inline
    fn __iadd__(mut self, other: Score):
        self._value += other._value

    @always_inline
    fn __isub__(mut self, other: Score):
        self._value -= other._value

    @always_inline
    fn __mul__(self, other: Score) -> Score:
        return self._value * other._value

    @always_inline
    fn __eq__(self, other: Score) -> Bool:
        return self._value == other._value

    @always_inline
    fn __ne__(self, other: Score) -> Bool:
        return self._value != other._value

    @always_inline
    fn __lt__(self, other: Score) -> Bool:
        return self._value < other._value

    @always_inline
    fn __le__(self, other: Score) -> Bool:
        return self._value <= other._value

    @always_inline
    fn __gt__(self, other: Score) -> Bool:
        return self._value > other._value

    @always_inline
    fn __ge__(self, other: Score) -> Bool:
        return self._value >= other._value

    @always_inline
    fn __neg__(self) -> Score:
        return Score(-self._value) if self._value != 0 else self

    @always_inline
    fn iswin(self) -> Bool:
        return isinf(self._value) and self._value > 0

    @always_inline
    fn isloss(self) -> Bool:
        return isinf(self._value) and self._value < 0

    @always_inline
    fn isdraw(self) -> Bool:
        return self._value == 0 and FPUtils.get_sign(self._value)

    @always_inline
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

