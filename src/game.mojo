trait TGame(Copyable, Defaultable):
    alias Move: TMove

    fn top_moves(self) -> List[Self.Move]:
        ...

    fn play_move(mut self, move: Self.Move):
        ...

trait TMove(Copyable, Movable, Defaultable, Stringable, Writable):
    alias Score: TScore

    fn score(self) -> Self.Score:
        ...

    fn set_score(mut self, score: Self.Score):
        ...

trait TScore(Copyable, LessThanComparable, Defaultable, Stringable, Writable):
    @staticmethod
    fn win() -> Self:
        ...

    @staticmethod
    fn loss() -> Self:
        ...

    @staticmethod
    fn draw() -> Self:
        ...

    fn value(self) -> Float32:
        ...

    fn min(self, other: Self) -> Self:
        ...

    fn __neg__(self) -> Self:
        ...

    fn is_win(self) -> Bool:
        ...

    fn is_loss(self) -> Bool:
        ...

    fn is_draw(self) -> Bool:
        ...

    fn is_decisive(self) -> Bool:
        ...
