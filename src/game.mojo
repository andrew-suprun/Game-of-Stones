from score import Score

trait TMove(Copyable, Movable, Stringable, Writable):
    fn __init__(out self):
        ...

    fn score(self) -> Score:
        ...

    fn set_score(mut self, score: Score):
        ...

    fn is_decisive(self) -> Bool:
        ...

trait TGame(Copyable):
    alias Move: TMove

    fn __init__(out self):
        ...

    fn name(self) -> String:
        ...

    fn top_moves(mut self, mut moves: List[Self.Move]):
        ...

    fn play_move(mut self, move: Self.Move):
        ...
