from utils.numerics import FPUtils, isinf, isnan, inf, nan


struct Score(Comparable, Defaultable, ImplicitlyCopyable, Movable, Stringable, TrivialRegisterPassable, Writable):
    var value: Float32

    @staticmethod
    fn win() -> Score:
        return Score(Float32.MAX)

    @staticmethod
    fn loss() -> Score:
        return Score(Float32.MIN)

    @staticmethod
    fn draw() -> Score:
        return Score(-0.0)

    fn __init__(out self):
        self = nan[DType.float32]()

    @implicit
    fn __init__(out self, value: IntLiteral):
        self.value = value

    @implicit
    fn __init__[dtype: DType](out self, value: SIMD[dtype, 1]):
        self.value = Float32(value)

    fn is_win(self) -> Bool:
        return isinf(self.value) and self.value > 0

    fn is_loss(self) -> Bool:
        return isinf(self.value) and self.value < 0

    fn is_draw(self) -> Bool:
        return self.value == 0 and FPUtils.get_sign(self.value)

    fn is_decisive(self) -> Bool:
        return isinf(self.value) or self.is_draw()

    fn is_set(self) -> Bool:
        return not isnan(self.value)

    fn __add__(self, other: Self) -> Score:
        return Score(self.value + other.value)

    fn __sub__(self, other: Self) -> Score:
        return Score(self.value - other.value)

    fn __iadd__(mut self, other: Self):
        self.value += other.value

    fn __isub__(mut self, other: Self):
        self.value -= other.value

    fn __mul__(self, other: Self) -> Score:
        return Score(self.value * other.value)

    fn __eq__(self, other: Self) -> Bool:
        if self.is_win() and not other.is_win():
            return False
        if self.is_loss() and not other.is_loss():
            return False
        if self.is_draw() and not other.is_draw():
            return False
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)

    fn __lt__(self, other: Self) -> Bool:
        return self.value < other.value

    fn __le__(self, other: Self) -> Bool:
        return self.value <= other.value

    fn __gt__(self, other: Self) -> Bool:
        return self.value > other.value

    fn __ge__(self, other: Self) -> Bool:
        return self.value >= other.value

    fn __neg__(self) -> Self:
        return Score(-self.value) if self.value != 0.0 else self

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if not self.is_set():
            writer.write("no-score")
        elif isinf(self.value):
            if self.value > 0:
                writer.write("win")
            else:
                writer.write("loss")
        elif self.is_draw():
            writer.write("draw")
        else:
            writer.write(String(self.value))
