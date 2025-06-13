from utils.numerics import inf, neg_inf, isfinite, isinf

trait Game(Stringable, Writable):
    # alias Move: EqualityComparableCollectionElement

    fn __init__(out self):
        ...

    fn name(self, out name: String):
        ...

    fn top_moves(mut self, mut move_scores: List[(Move, Score)]):
        ...

    fn play_move(mut self, move: Move):
        ...

    fn undo_move(mut self):
        ...

    fn decision(self, out decision: String):
        ...


# TODO Make it alias type in Game
@value
@register_passable("trivial")
struct Move(Movable, Copyable, EqualityComparable, Representable, Stringable, Writable):
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
    fn __eq__(self, other: Self, out result: Bool):
        result = self.p1 == other.p1 and self.p2 == other.p2 or
            self.p1 == other.p2 and self.p1 == other.p1

    @always_inline
    fn __ne__(self, other: Self, out result: Bool):
        result = not (self == other)

    fn __repr__(self, out r: String):
        r = String(self)

    fn __str__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self.p1 != self.p2:
            writer.write(self.p1, "-", self.p2)
        else:
            writer.write(self.p1)

@value
@register_passable("trivial")
struct Place(KeyElement, Stringable, Writable):
    var x: Int8
    var y: Int8

    fn __init__(out self, place: String) raises:
        self.x = ord(place[0]) - ord("a")
        self.y = Int(place[1:]) - 1

    @always_inline
    fn __eq__(self, other: Self, out result: Bool):
        result = self.x == other.x and self.y == other.y

    @always_inline
    fn __ne__(self, other: Self, out result: Bool):
        result = not (self == other)

    fn __hash__(self, out result: UInt):
        return hash(self.x) + hash(self.y) * 41

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(chr(Int(self.x) + ord("a")), self.y + 1)

alias Score = Float32
alias Scores = SIMD[DType.float32, 2]
alias win = inf[DType.float32]()
alias loss = neg_inf[DType.float32]()
alias draw = Score(0.25)


@always_inline
fn is_decisive(v: Score, out result: Bool):
    return not isfinite(v) or is_draw(v)


@always_inline
fn is_win(v: Score, out result: Bool):
    return isinf(v) and v > 0


@always_inline
fn is_loss(v: Score, out result: Bool):
    return isinf(v) and v < 0


@always_inline
fn is_draw(v: Score, out result: Bool):
    return v == draw
