trait Game(ExplicitlyCopyable):
    # alias Move: EqualityComparableCollectionElement

    fn top_moves(self, mut moves: List[Move], mut values: List[Float32]):
        ...

    fn play_move(mut self, move: Move):
        ...


# TODO Make it alias type in Game
@value
struct Move(EqualityComparableCollectionElement, Stringable, Writable):
    var p1: Place
    var p2: Place

    fn __init__(out self, x1: Int, y1: Int, x2: Int, y2: Int):
        self.p1 = Place(x1, y1)
        self.p2 = Place(x2, y2)

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.p1 == other.p1 and self.p2 == other.p2 or
            self.p1 == other.p2 and self.p1 == other.p1

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)

    fn __str__(self) -> String:
        return String(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.p1, "-", self.p2)



@value
struct Place(EqualityComparableCollectionElement, Stringable, Writable):
    var x: Int8
    var y: Int8

    fn __init__(out self, x: Int, y: Int):
        self.x = x
        self.y = y

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)

    fn __str__(self) -> String:
        return String(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(chr(Int(self.x) + ord("a")), self.y+1)


