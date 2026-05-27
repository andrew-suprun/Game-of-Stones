trait TTree(Defaultable, ImplicitlyDestructible, Writable):
    comptime Game: TGame

    def search(mut self, game: Self.Game, max_time_ms: UInt, out pv: List[Self.Game.Move]):
        ...


trait TGame(Copyable, Defaultable, ImplicitlyDestructible, Writable):
    comptime Move: TMove

    def top_moves(self) -> List[MoveScore[Self.Move]]:
        ...

    def play_move(mut self, move: Self.Move):
        ...

    def score(self) -> Score:
        ...


trait TMove(Copyable, Defaultable, TrivialRegisterPassable, Writable):
    @implicit
    def __init__(out self, text: String) raises:
        ...


@fieldwise_init
struct Score(Comparable, Copyable, Floatable, TrivialRegisterPassable, Writable):
    var _value: Float32

    def __init__(out self):
        self._value = Loss

    def __float__(self) -> Float64:
        return Float64(self._value)

    @staticmethod
    def win() -> Score:
        return Score(Float32.MAX)

    @staticmethod
    def loss() -> Score:
        return Score(Float32.MIN)

    @staticmethod
    def draw() -> Score:
        return Score(nan[Float32.dtype]())

    def is_win(self) -> Bool:
        return isinf(self._value) and self._value > 0

    def is_loss(self) -> Bool:
        return isinf(self._value) and self._value < 0

    def is_draw(self) -> Bool:
        return isnan(self._value)

    def is_decisive(self) -> Bool:
        return isinf(self._value) or self.is_draw()

    def max(self, other: Score) -> Score:
        var self_v = self._value if not self.is_draw() else 0
        var other_v = other._value if not other.is_draw() else 0
        return self if self_v > other_v else other

    def min(self, other: Score) -> Score:
        var self_v = self._value if not self.is_draw() else 0
        var other_v = other._value if not other.is_draw() else 0
        return self if self_v < other_v else other

    def __eq__(self, other: Score) -> Bool:
        var self_v = self._value if not self.is_draw() else 0
        var other_v = other._value if not other.is_draw() else 0
        return self_v == other_v

    def __lt__(self, other: Score) -> Bool:
        var self_v = self._value if not self.is_draw() else 0
        var other_v = other._value if not other.is_draw() else 0
        return self_v < other_v

    def __add__(self, other: Score) -> Score:
        return Score(self._value + other._value)

    def __mul__(self, other: Score) -> Score:
        return Score(self._value * other._value)

    def __truediv__(self, other: Score) -> Score:
        return Score(self._value / other._value)

    def __neg__(self) -> Score:
        return Score(-self._value)

    def write_to[W: Writer](self, mut writer: W):
        if isinf(self._value):
            if self._value > 0:
                writer.write("win")
            else:
                writer.write("loss")
        elif self.is_draw():
            writer.write("draw")
        else:
            return writer.write(self._value)


@fieldwise_init
struct MoveScore[Move: TMove](Copyable, TrivialRegisterPassable, Writable):
    var move: Self.Move
    var score: Score
