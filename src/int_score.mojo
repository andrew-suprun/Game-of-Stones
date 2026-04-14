from traits import TScore


comptime Win = Int16.MAX
comptime Loss = -Win
comptime NoScore = Int16.MIN
comptime Draw = Loss+1

struct Score(TScore):
    var value: Int16

    @staticmethod
    def win() -> Score:
        return Score(Win)

    @staticmethod
    def loss() -> Score:
        return Score(Loss)

    @staticmethod
    def draw() -> Score:
        return Score(Draw)

    def __init__(out self):
        self = Score(NoScore)

    @implicit
    def __init__(out self, value: IntLiteral):
        self.value = value

    @implicit
    def __init__[dtype: DType](out self, value: Scalar[dtype]):
        self.value = Int16(value)

    def is_win(self) -> Bool:
        return self.value == Win

    def is_loss(self) -> Bool:
        return self.value == Loss

    def is_draw(self) -> Bool:
        return self.value == Draw

    def is_decisive(self) -> Bool:
        return self.is_win() or self.is_loss() or self.is_draw()

    def is_set(self) -> Bool:
        return self.value != NoScore

    def __add__(self, other: Self) -> Score:
        debug_assert(self.value > Draw and self.value < Win and other.value > Draw)
        return other if other.is_decisive() else self.value + other.value

    def __sub__(self, other: Self) -> Score:
        debug_assert(self.value > Draw and self.value < Win and other.value > Draw)
        return -other if other.is_decisive() else self.value - other.value

    def __iadd__(mut self, other: Self):
        debug_assert(self.value > Draw and self.value < Win)
        self.value = other.value if other.is_decisive() else self.value + other.value

    def __isub__(mut self, other: Self):
        debug_assert(self.value > Draw and self.value < Win and other.value > Draw)
        self.value = (-other).value if other.is_decisive() else self.value - other.value

    def __mul__(self, other: Self) -> Score:
        debug_assert(self.value > Draw and self.value < Win and other.value > Draw)
        return Win if other.is_win() else Score(self.value * other.value)

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
        var self_value = 0 if self.is_draw() else self.value
        var other_value = 0 if other.is_draw() else other.value
        return self_value < other_value

    def __neg__(self) -> Self:
        return Draw if self.is_draw() else Score(-self.value)

    def write_to[W: Writer](self, mut writer: W):
        if not self.is_set():
            writer.write("no-score")
        elif self.is_win():
            writer.write("win")
        elif self.is_loss():
            writer.write("Loss")
        elif self.is_draw():
            writer.write("draw")
        else:
            writer.write(String(self.value))
