from utils.numerics import inf, neg_inf, isinf, FPUtils

@fieldwise_init
struct Score(Copyable, Movable, Floatable, Comparable, Stringable, Writable):
    alias _win_value = inf[DType.float32]()
    alias _draw_value = Float32(-0.0)
    alias _loss_value = neg_inf[DType.float32]()

    var _value: Float32

    @staticmethod
    fn win() -> Score:
        return Score(Self._win_value)

    @staticmethod
    fn draw() -> Score:
        return Score(Self._draw_value)
 
    @staticmethod
    fn loss() -> Score:
        return Score(Self._loss_value)

    @implicit
    fn __init__(out self, value: Int):
        return Score(Float32(value))

    @implicit
    fn __init__(out self, value: Float64):
        return Score(Float32(value))

    fn __neg__(self) -> Score:
        debug_assert(not self.isdecisive())
        return Score(-self._value)

    fn iswin(self) -> Bool:
        return isinf(self._value) and self._value > 0

    fn isloss(self) -> Bool:
        return isinf(self._value) and self._value < 0

    fn isdraw(self) -> Bool:
        return self._value == 0 and FPUtils.get_sign(self._value)

    fn isdecisive(self) -> Bool:
        return isinf(self._value) or self.isdraw()

    fn __iadd__(mut self, other: Self):
        self._value += other._value

    fn __sub__(self, other: Self) -> Self:
        return Score(self._value - other._value)

    fn __isub__(mut self, other: Self):
        self._value -= other._value

    fn __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    fn __ne__(self, other: Self) -> Bool:
        return self._value != other._value

    fn __lt__(self, other: Self) -> Bool:
        return self._value < other._value

    fn __le__(self, other: Self) -> Bool:
        return self._value <= other._value

    fn __gt__(self, other: Self) -> Bool:
        return self._value > other._value

    fn __ge__(self, other: Self) -> Bool:
        return self._value >= other._value

    fn __float__(self) -> Float64:
        debug_assert(not self.isdecisive())
        return Float64(self._value)

    fn __str__(self) -> String:
        if self.iswin():
            return "win"
        if self.isloss():
            return "loss"
        if self.isdraw():
            return "draw"
        return String(self._value)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(String(self))
