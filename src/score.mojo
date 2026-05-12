from std.sys.defines import get_defined_string
from std.utils.numerics import FPUtils, isinf, isnan, isfinite, inf, nan

comptime AssertMode = get_defined_string["ASSERT", "none"]()
comptime Assert = AssertMode == "all"

comptime Value = Float32
comptime Win = Score(Value.MAX)
comptime Loss = Score(Value.MIN)
comptime Draw = nan[Value.dtype]()


struct Score(Comparable, Defaultable, Floatable, TrivialRegisterPassable, Writable):
    var value: Value

    def __init__(out self):
        self = Loss

    @implicit
    def __init__(out self, value: IntLiteral):
        self.value = value

    @implicit
    def __init__[dtype: DType](out self, value: Scalar[dtype]):
        self.value = Value(value)

    def __float__(self) -> Float64:
        return Float64(self.value)

    def is_win(self) -> Bool:
        return isinf(self.value) and self.value > 0

    def is_loss(self) -> Bool:
        return isinf(self.value) and self.value < 0

    def is_draw(self) -> Bool:
        return isnan(self.value)

    def is_decisive(self) -> Bool:
        return not isfinite(self.value)

    def __add__(self, other: Self) -> Score:
        return Score(self.value + other.value)

    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value or self.is_draw() and other.is_draw()

    def __lt__(self, other: Self) -> Bool:
        var self_value = self.value if not self.is_draw() else 0
        var other_value = other.value if not other.is_draw() else 0
        return self_value < other_value

    def __neg__(self) -> Self:
        return -self.value if not self.is_draw() else Draw

    @staticmethod
    def max(a: Score, b: Score) -> Score:
        if a.is_draw() and b.is_draw():
            return Draw
        var a_value = a.value if not a.is_draw() else 0
        var b_value = b.value if not b.is_draw() else 0
        if a_value < b_value:
            return b
        else:
            return a

    @staticmethod
    def min(a: Score, b: Score) -> Score:
        if a.is_draw() and b.is_draw():
            return Draw
        var a_value = a.value if not a.is_draw() else 0
        var b_value = b.value if not b.is_draw() else 0
        if a_value >= b_value:
            return b
        else:
            return a

    def write_to[W: Writer](self, mut writer: W):
        if isinf(self.value):
            if self.value > 0:
                writer.write("win")
            else:
                writer.write("loss")
        elif self.is_draw():
            writer.write("draw")
        else:
            writer.write(String(self.value))
