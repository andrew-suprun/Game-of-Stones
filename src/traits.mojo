from score import Score


trait TTree:
    comptime Game: TGame

    fn __init__(out self):
        ...

    fn search(mut self, game: Self.Game, state: Self.Game.State, max_time_ms: UInt) -> MoveScore[Self.Game.State.Move]:
        ...


trait TGame(Defaultable):
    comptime State: TState

    fn moves(self, state: Self.State) -> List[MoveScore[Self.State.Move]]:
        ...

    fn play_move(self, state: Self.State, move: Self.State.Move) -> Self.State:
        ...

trait TState(Copyable, Defaultable, Stringable, Writable):
    comptime Move: TMove

    fn score(self) -> Score:
        ...

trait TMove(Defaultable, Equatable, ImplicitlyCopyable, Representable, Stringable, Writable, TrivialRegisterType):
    fn __init__(out self, text: String) raises:
        ...


@fieldwise_init
struct MoveScore[Move: TMove](ImplicitlyCopyable, Representable, Stringable, Writable, TrivialRegisterType):
    var move: Self.Move
    var score: Score

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

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
