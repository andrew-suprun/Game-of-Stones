from scores import Score
from board import Place

trait Game:
    # alias Move: EqualityComparableCollectionElement

    fn top_moves(mut self, mut move_scores: List[MoveScore]):
        ...

    fn play_move(mut self, move: Move):
        ...

    fn undo_move(mut self):
        ...

    fn score(self, out score: Score):
        ...


# TODO Make it alias type in Game
@value
@register_passable("trivial")
struct Move(CollectionElement, EqualityComparable, Representable, Stringable, Writable):
    var p1: Place
    var p2: Place

    fn __init__(out self, x1: Int, y1: Int, x2: Int, y2: Int):
        self.p1 = Place(x1, y1)
        self.p2 = Place(x2, y2)

    fn __init__(out self, move: String) raises:
        var tokens = move.split("-")
        self.p1 = Place(tokens[0])
        if len(tokens) == 2:
            self.p2 = Place(tokens[1])
        else:
            self.p2 = self.p1


    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.p1 == other.p1 and self.p2 == other.p2 or
            self.p1 == other.p2 and self.p1 == other.p1

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)

    fn __repr__(self, out r: String):
        r = String(self)

    fn __str__(self, out r: String):
        r = String(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.p1, "-", self.p2)


@value
@register_passable("trivial")
struct MoveScore(CollectionElement, Representable, Stringable, Writable):
    var move: Move
    var score: Score

    fn __repr__(self, out r: String):
        r = String(self)

    fn __str__(self) -> String:
        return String(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.move, " v: ", self.score)
