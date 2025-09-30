from score import Score


trait TGame(Defaultable, Stringable, Writable):
    alias Move: TMove

    fn moves(mut self) -> List[MoveScore[Self.Move]]:
        ...

    fn move(mut self) -> MoveScore[Self.Move]:
        ...

    fn play_move(mut self, move: Self.Move) -> Score:
        ...

    fn undo_move(mut self, move: Self.Move):
        ...

    fn hash(self) -> Int:
        ...


trait TMove(Defaultable, Hashable, ImplicitlyCopyable, Movable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...

@fieldwise_init
struct MoveScore[Move: TMove](ImplicitlyCopyable, Movable, Writable):
    var move: Move
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