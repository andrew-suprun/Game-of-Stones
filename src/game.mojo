from score import Score, is_win, is_loss, is_draw


trait TGame(ExplicitlyCopyable, Defaultable, Stringable, Writable):
    alias Move: TMove

    fn moves(self, max_moves: Int) -> List[MoveScore[Move]]:
        ...

    fn play_move(mut self, move: Move):
        ...

    fn score(self) -> Score:
        ...

    fn is_terminal(self) -> Bool:
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
        if is_win(self.score):
            writer.write(" win")
        elif is_loss(self.score):
            writer.write(" loss")
        elif is_draw(self.score):
            writer.write(" draw")
        else:
            writer.write(" ", self.score)
