from std.utils.numerics import FPUtils, isinf, isnan, inf, nan

comptime Value = Float32
comptime Win = Score(Value.MAX)
comptime Loss = Score(Value.MIN)
comptime Draw = Score(-0.0)

struct Score(Comparable, Defaultable, ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    var value: Value

    def __init__(out self):
        self = nan[DType.float32]()

    @implicit
    def __init__(out self, value: IntLiteral):
        self.value = value

    @implicit
    def __init__[dtype: DType](out self, value: Scalar[dtype]):
        self.value = Value(value)

    def is_win(self) -> Bool:
        return isinf(self.value) and self.value > 0

    def is_loss(self) -> Bool:
        return isinf(self.value) and self.value < 0

    def is_draw(self) -> Bool:
        return self.value == 0 and FPUtils.get_sign(self.value)

    def is_decisive(self) -> Bool:
        return isinf(self.value) or self.is_draw()

    def __add__(self, other: Self) -> Score:
        debug_assert(self.is_set() and not self.is_decisive() and other.is_set() and not other.is_loss() and not other.is_draw())
        return Score(self.value + other.value)

    def __sub__(self, other: Self) -> Score:
        debug_assert(self.is_set() and not self.is_decisive() and other.is_set() and not other.is_loss() and not other.is_draw())
        return Score(self.value - other.value)

    # def __iadd__(mut self, other: Self):
    #     debug_assert(self.is_set() and not self.is_decisive() and other.is_set() and not other.is_loss() and not other.is_draw())
    #     self.value += other.value

    # def __isub__(mut self, other: Self):
    #     debug_assert(self.is_set() and not self.is_decisive() and other.is_set() and not other.is_loss() and not other.is_draw())
    #     self.value -= other.value

    # def __mul__(self, other: Self) -> Score:
    #     debug_assert(self.is_set() and not self.is_decisive() and other.is_set() and not other.is_loss() and not other.is_draw())
    #     return Score(self.value * other.value)

    def __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    def __lt__(self, other: Self) -> Bool:
        return self.value < other.value

    def __neg__(self) -> Self:
        return Score(-self.value) if self.value != 0.0 else self
    
    @staticmethod
    def max(a: Score, b: Score) -> Score:
        if a.is_draw() and b.is_draw():
            return Self.draw()
        return (a if a > b else b) + 0.0 # '+ 0.0' to avoid accidental draws

    def write_to[W: Writer](self, mut writer: W):
        if isnan(self.value):
            writer.write("NO-SCORE")
        elif isinf(self.value):
            if self.value > 0:
                writer.write("win")
            else:
                writer.write("loss")
        elif self.is_draw():
            writer.write("draw")
        else:
            writer.write(String(self.value))