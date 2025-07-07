from score import Score

trait TGame(Copyable, Stringable, Writable):
    alias Move: TMove

    fn moves(self) -> List[(Move, Score)]:
        ...

    fn play_move(mut self, move: Move):
        ...


# TODO: Remove Defaultable after removing Node.root
trait TMove(Copyable, Movable, Defaultable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...
