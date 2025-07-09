from game import TScore

@fieldwise_init
struct Score(TScore):
    alias _win_value = Int32.MAX
    alias _draw_value = Int32.MAX-1
    alias _loss_value = Int32.MAX-2

    var _value: Int32

    @staticmethod
    fn win() -> Score:
        return Score(Self._win_value)

    @staticmethod
    fn draw() -> Score:
        return Score(Self._draw_value)

    @staticmethod
    fn loss() -> Score:
        return Score(Self._loss_value)

    fn __init__(out self, value: Int):
        return Score(Int32(value))

    fn __init__(out self, value: Float64):
        return Score(Int32(value))

    fn __invert__(self) -> Score:
        debug_assert(not self.isdecisive())
        return Score(-self._value)

    fn iswin(self) -> Bool:
        return self._value == Self._win_value

    fn isloss(self) -> Bool:
        return self._value == Self._loss_value

    fn isdraw(self) -> Bool:
        return self._value == Self._draw_value

    fn isdecisive(self) -> Bool:
        return self._value >= Self._loss_value

    fn __lt__(self, other: Self) -> Bool:
        debug_assert(not self.isdecisive())
        return self._value < other._value

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
        writer.write(self)
