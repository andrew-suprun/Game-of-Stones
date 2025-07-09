trait TGame(Copyable, Defaultable, Stringable, Writable):
    alias Move: TMove
    alias Score: TScore

    fn moves(self) -> List[(Move, Score)]:
        ...

    fn play_move(mut self, move: Move):
        ...

    fn decision(self) -> StaticString:
        ...

# TODO: Remove Defaultable after removing Node.root
trait TMove(Copyable, Movable, Defaultable, Stringable, Writable):
    fn __init__(out self, text: String) raises:
        ...

trait TScore(Copyable, Movable, Floatable, LessThanComparable, Stringable, Writable):
    @staticmethod
    fn win() -> Self:
        ...

    @staticmethod
    fn loss() -> Self:
        ...

    @staticmethod
    fn draw() -> Self:
        ...

    fn __init__(out self, value: Int):
        ...

    fn __init__(out self, value: Float64):
        ...

    fn iswin(self) -> Bool:
        ...

    fn isdraw(self) -> Bool:
        ...

    fn isloss(self) -> Bool:
        ...

    fn isdecisive(self) -> Bool:
        ...


