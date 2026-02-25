from score import Score


trait TTree(ImplicitlyDestructible):
    comptime Game: TGame

    fn __init__(out self):
        ...

    fn search(mut self, game: Self.Game, max_time_ms: UInt) -> MoveScore[Self.Game.Move]:
        ...


trait TGame(Copyable, Defaultable, Writable):
    comptime Move: TMove

    fn moves(self) -> List[MoveScore[Self.Move]]:
        ...

    fn play_move(mut self, move: Self.Move) -> Score:
        ...


trait TMove(Defaultable, Equatable, ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    fn __init__(out self, text: String) raises:
        ...


@fieldwise_init
struct MoveScore[Move: TMove](ImplicitlyCopyable, TrivialRegisterPassable, Writable):
    var move: Self.Move
    var score: Score

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.move)
        if self.score.is_win():
            writer.write(" win")
        elif self.score.is_loss():
            writer.write(" loss")
        elif self.score.is_draw():
            writer.write(" draw")
        else:
            writer.write(" ", self.score)
