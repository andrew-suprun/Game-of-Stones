from utils.numerics import inf, neg_inf, isfinite, isinf

trait TMove(Copyable, Movable, Stringable, Writable):
    # TODO: fields in traits are not supported yet
    # var _score: Float32
    # fn score(mut self) -> ref[self._score] Float32:

    fn __init__(out self):
        ...

    fn get_score(self) -> Float32:
        ...

    fn set_score(mut self, score: Float32):
        ...

    fn is_decisive(self) -> Bool:
        ...

    fn set_decisive(mut self):
        ...


trait TGame:
    alias Move: TMove

    fn __init__(out self):
        ...

    fn name(self) -> String:
        ...

    fn top_moves(mut self, mut move_scores: List[Self.Move]):
        ...

    fn play_move(mut self, move: Self.Move):
        ...

    fn undo_move(mut self):
        ...
