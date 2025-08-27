from score import Score


trait TGame(Defaultable, ExplicitlyCopyable, Stringable, Writable):
    alias Move: TMove

    fn moves(self) -> List[MoveScore[Move]]:
        ...

    fn move(self) -> MoveScore[Move]:
        ...

    fn play_move(mut self, move: Move) -> Score:
        ...

    fn hash(self) -> Int:
        ...


trait TMove(Copyable, Defaultable, Hashable, Movable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...


@fieldwise_init
struct MoveScore[Move: TMove](Copyable, Movable, Writable):
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
