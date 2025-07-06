alias Decision = Int
alias win: Decision = 1
alias loss: Decision = -1
alias draw: Decision = 0
alias undecided: Decision = 2

trait TGame(Copyable, Stringable, Writable):
    alias Move: TMove

    fn moves(self) -> List[Self.Move]:
        ...

    fn play_move(mut self, move: Self.Move):
        ...

trait TMove(Copyable, Movable, Defaultable, Stringable, Writable):
    alias Score: TScore

    fn __init__(out self, text: String) raises:
        ...

    fn decision(self) -> Decision:
        ...

    fn score(self) -> Score:
        ...

    fn setscore(mut self, score: Score):
        ...


trait TScore(Floatable, Copyable, Movable, Comparable, Stringable, Writable):
    fn __init__(out self, value: IntLiteral):
        ...

    fn min(self, other: Self) -> Self:
        ...

    fn max(self, other: Self) -> Self:
        ...

    fn __add__(self, other: Self) -> Self:
        ...

    fn __sub__(self, other: Self) -> Self:
        ...

    fn __iadd__(mut self, other: Self):
        ...

    fn __isub__(mut self, other: Self):
        ...

    fn __mul__(self, other: Self) -> Self:
        ...

    fn __neg__(self) -> Self:
        ...