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

@fieldwise_init
struct Decision(Copyable, Movable, EqualityComparable, Stringable, Writable):
    alias undecided = Decision(-2)
    alias loss = Decision(-1)
    alias draw = Decision(0)
    alias win = Decision(1)

    var _value: Byte

    fn decided(self) -> Bool:
        return self._value > 0

    fn __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    fn __ne__(self, other: Self) -> Bool:
        return self._value != other._value

    fn __str__(self) -> String:
        return String.write(self)

    alias _decisions = ["undecided", "loss", "draw", "win"]

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(Self._decisions[self._value + 2])

