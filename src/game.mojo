trait TGame(Copyable, Defaultable, Writable):
    alias Move: TMove

    fn moves(self) -> List[Self.Move]:
        ...

    fn play_move(mut self, move: Self.Move):
        ...

    fn decision(self) -> StaticString:
        ...

trait TMove(Copyable, Movable, Defaultable, Stringable, Representable, Writable):
    alias Score: TScore

    fn __init__(out self, text: String) raises:
        ...

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

    fn max(self, other: Self) -> Self:
        ...

    fn __neg__(self) -> Self:
        ...

    fn iswin(self) -> Bool:
        ...

    fn isloss(self) -> Bool:
        ...

    fn isdraw(self) -> Bool:
        ...

    fn is_decisive(self) -> Bool:
        ...
