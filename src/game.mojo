from score import Score


trait TGame(Copyable, Defaultable, Movable, Stringable, Writable):
    alias Move: TMove

    fn moves(self) -> List[MoveScore[Self.Move]]:
        ...

    fn move(self) -> MoveScore[Self.Move]:
        ...

    fn play_move(mut self, move: Self.Move) -> Score:
        ...

    fn hash(self) -> Int:
        ...


trait TMove(Defaultable, Hashable, ImplicitlyCopyable, Movable, Representable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...


@fieldwise_init
struct MoveScore[Move: TMove](ImplicitlyCopyable, Movable, Representable, Stringable, Writable):
    var move: Move
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
