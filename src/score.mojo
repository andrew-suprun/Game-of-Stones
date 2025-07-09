from game import TScore

@fieldwise_init
struct Score(TScore):
    alias _win = Int8(1)
    alias _loss = Int8(-1)
    alias _draw = Int8(0)
    alias _undecided = Int8(2)

    alias _win_score = Score(Int32.MAX, Self._win)
    alias _loss_score = Score(Int32.MIN, Self._loss)
    alias _draw_score = Score(0, Self._draw)

    var _value: Int32
    var _decision: Int8

    @staticmethod
    fn win() -> Score:
        return Self._win_score

    @staticmethod
    fn draw() -> Score:
        return Self._draw_score

    @staticmethod
    fn loss() -> Score:
        return Self._loss_score

    fn __init__(out self, value: Int32):
        return Score(value, Self._undecided)

    fn __init__(out self, value: Int):
        return Score(value, Self._undecided)

    fn __init__(out self, value: Float64):
        return Score(Int32(value), Self._undecided)

    fn __invert__(self) -> Score:
        debug_assert(self._decision == Self._undecided)
        return Score(-self._value, Self._undecided)

    fn iswin(self) -> Bool:
        return self._decision == Self._win

    fn isloss(self) -> Bool:
        return self._decision == Self._loss

    fn isdraw(self) -> Bool:
        return self._decision == Self._draw

    fn isdecisive(self) -> Bool:
        return self._decision != Self._undecided

    fn __lt__(self, other: Self) -> Bool:
        debug_assert(self._decision == Self._undecided)
        return self._value < other._value

    fn __float__(self) -> Float64:
        debug_assert(self._decision == Self._undecided)
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
