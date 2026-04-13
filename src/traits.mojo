trait TTree(ImplicitlyDestructible):
    comptime Game: TGame

    def __init__(out self):
        ...

    def search(mut self, game: Self.Game, max_time_ms: UInt) -> MoveScore[Self.Game.Move, Self.Game.Score]:
        ...


trait TGame(Copyable, Defaultable, Writable):
    comptime Move: TMove
    comptime Score: TScore

    def moves(self) -> List[MoveScore[Self.Move, Self.Score]]:
        ...

    def play_move(mut self, move: Self.Move) -> Self.Score:
        ...


trait TMove(Defaultable, Equatable, ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    def __init__(out self, text: String) raises:
        ...


trait TScore(Comparable, Defaultable, ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    @staticmethod
    def win() -> Self:
        ...

    @staticmethod
    def loss() -> Self:
        ...

    @staticmethod
    def draw() -> Self:
        ...

    def __init__(out self):
        ...

    @implicit
    def __init__(out self, value: IntLiteral):
        ...

    @implicit
    def __init__[dtype: DType](out self, value: Scalar[dtype]):
        ...

    def is_win(self) -> Bool:
        ...

    def is_loss(self) -> Bool:
        ...

    def is_draw(self) -> Bool:
        ...

    def is_decisive(self) -> Bool:
        return self.is_win() or self.is_loss() or self.is_draw()

    def is_set(self) -> Bool:
        ...

    def __add__(self, other: Self) -> Self:
        ...

    def __sub__(self, other: Self) -> Self:
        ...

    def __iadd__(mut self, other: Self):
        ...

    def __isub__(mut self, other: Self):
        ...

    def __mul__(self, other: Self) -> Self:
        ...

    def __neg__(self) -> Self:
        ...




@fieldwise_init
struct MoveScore[Move: TMove, Score: TScore](ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    var move: Self.Move
    var score: Self.Score

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.move)
        if self.score.is_win():
            writer.write(" win")
        elif self.score.is_loss():
            writer.write(" loss")
        elif self.score.is_draw():
            writer.write(" draw")
        else:
            writer.write(" ", self.score)
