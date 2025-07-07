trait TGame(Copyable, Stringable, Writable):
    alias Move: TMove

    fn moves(self) -> List[(Move, Float32, Decision)]:
        ...

    fn play_move(mut self, move: Move):
        ...


# TODO: Remove Defaultable after removing Node.root
trait TMove(Copyable, Movable, Defaultable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...


@fieldwise_init
struct Decision(Copyable, Movable, EqualityComparable, Stringable, Writable):
    alias undecided = Decision(-2)
    alias loss = Decision(-1)
    alias draw = Decision(0)
    alias win = Decision(1)

    var _value: Byte

    fn __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    fn __ne__(self, other: Self) -> Bool:
        return self._value != other._value

    fn __str__(self) -> String:
        return String.write(self)

    alias _decisions = ["undecided", "loss", "draw", "win"]

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(Self._decisions[self._value + 2])

