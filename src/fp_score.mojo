from std.utils.numerics import FPUtils, isinf, isnan, inf, nan

from traits import TScore


struct Score(TScore):
    var value: Float32

    @staticmethod
    def win() -> Score:
        return Score(Float32.MAX)

    @staticmethod
    def loss() -> Score:
        return Score(Float32.MIN)

    @staticmethod
    def draw() -> Score:
        return Score(-0.0)

    def __init__(out self):
        self = nan[DType.float32]()

    @implicit
    def __init__(out self, value: IntLiteral):
        self.value = value

    @implicit
    def __init__[dtype: DType](out self, value: Scalar[dtype]):
        self.value = Float32(value)

    def is_win(self) -> Bool:
        return isinf(self.value) and self.value > 0

    def is_loss(self) -> Bool:
        return isinf(self.value) and self.value < 0

    def is_draw(self) -> Bool:
        return self.value == 0 and FPUtils.get_sign(self.value)

    def is_decisive(self) -> Bool:
        return isinf(self.value) or self.is_draw()

    def is_set(self) -> Bool:
        return not isnan(self.value)

    def __add__(self, other: Self) -> Score:
        debug_assert(self.is_set() and not self.is_decisive() and other.is_set())
        return Score(self.value + other.value)

    def __sub__(self, other: Self) -> Score:
        debug_assert(self.is_set() and not self.is_decisive() and other.is_set())
        return Score(self.value - other.value)

    def __iadd__(mut self, other: Self):
        debug_assert(self.is_set() and not self.is_decisive() and other.is_set())
        self.value += other.value

    def __isub__(mut self, other: Self):
        debug_assert(self.is_set() and not self.is_decisive() and other.is_set())
        self.value -= other.value

    def __mul__(self, other: Self) -> Score:
        debug_assert(self.is_set() and not self.is_decisive() and other.is_set())
        return Score(self.value * other.value)

    def __eq__(self, other: Self) -> Bool:
        if self.is_win() and not other.is_win():
            return False
        if self.is_loss() and not other.is_loss():
            return False
        if self.is_draw() and not other.is_draw():
            return False
        return self.value == other.value

    def __ne__(self, other: Self) -> Bool:
        return not (self == other)

    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value

    def __le__(self, other: Self) -> Bool:
        return self.value <= other.value

    def __gt__(self, other: Self) -> Bool:
        return self.value > other.value

    def __ge__(self, other: Self) -> Bool:
        return self.value >= other.value

    def __neg__(self) -> Self:
        return Score(-self.value) if self.value != 0.0 else self

    def write_to[W: Writer](self, mut writer: W):
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
