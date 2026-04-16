comptime Score = Int32


trait TTree(ImplicitlyDestructible):
    comptime Game: TGame

    def __init__(out self):
        ...

    def search(mut self, game: Self.Game, max_time_ms: UInt) -> MoveScore[Self.Game.Move]:
        ...


trait TGame(Copyable, Defaultable, Writable):
    comptime Move: TMove

    def moves(self) -> List[MoveScore[Self.Move]]:
        ...

    def play_move(mut self, move: Self.Move):
        ...


trait TMove(Defaultable, Equatable, ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    def __init__(out self, text: String) raises:
        ...

    def is_terminal(self) -> Bool:
        ...


@fieldwise_init
struct MoveScore[Move: TMove](ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    var move: Self.Move
    var score: Score

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.move, " ", self.score)
