@fieldwise_init
struct Place(Comparable, Copyable, Defaultable, TrivialRegisterPassable, Writable):
    var x: Int
    var y: Int

    def __init__(out self):
        self.x = -1
        self.y = -1

    @implicit
    def __init__(out self, place: String) raises:
        self.x = Int(ord(place[byte=0]) - ord("a"))
        self.y = Int(Int(place[byte=1:]) - 1)

    def __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y

    def __lt__(self, other: Self) -> Bool:
        return self.x < other.x or self.x == other.x and self.y < other.y

    def write_to[W: Writer](self, mut writer: W):
        writer.write(chr(Int(self.x) + ord("a")), self.y + 1)


@fieldwise_init
struct Stone(Equatable, ImplicitlyCopyable, Writable):
    var value: Int8

    comptime none = Stone(0)
    comptime black = Stone(1)
    comptime white = Stone(2)


@fieldwise_init
struct IndexRange(ImplicitlyCopyable):
    var start: Int
    var end: Int


struct Board[size: Int, win_stones: Int](Defaultable, Writable):
    comptime Stones = SIMD[DType.int8, 2]
    comptime SegmentIndicesAggregate = InlineArray[IndexRange, 4]
    comptime Indices = InlineArray[Self.SegmentIndicesAggregate, Self.size * Self.size]
    comptime Segments = InlineArray[Self.Stones, Self._calc_n_segments()]
    comptime Places = InlineArray[Stone, Self.size * Self.size]

    comptime indices = Self._calc_indices()

    var _places: Self.Places
    var _segments: Self.Segments

    def __init__(out self):
        self._places = Self.Places(fill=Stone.none)
        self._segments = Self.Segments(fill={0, 0})

    def __getitem__(ref self, x: Int, y: Int) -> ref[self._places] Stone:
        return self._places[y * Self.size + x]

    def place_stone(mut self, place: Place, stone: Stone):
        self[place.x, place.y] = stone
        if stone == Stone.black:
            self._place_stone[0](place, 1)
        else:
            self._place_stone[1](place, 1)

    def remove_stone(mut self, place: Place, stone: Stone):
        self[place.x, place.y] = Stone.none
        if stone == Stone.black:
            self._place_stone[0](place, -1)
        else:
            self._place_stone[1](place, -1)

    def _place_stone[turn: Int](mut self, place: Place, sign: Int8):
        var offset = place.y * Self.size + place.x
        var index_ranges = self.indices[offset]
        comptime for i in range(4):
            var index_range = index_ranges[i]
            for i in range(index_range.start, index_range.end):
                self._segments[i][turn] += sign

    @staticmethod
    def _calc_n_segments() -> Int:
        return (
            Self.size * (Self.size - Self.win_stones + 1) * 2
            + (Self.size - Self.win_stones + 2) * (Self.size - Self.win_stones + 1)
            + (Self.size - Self.win_stones + 1) * (Self.size - Self.win_stones)
        )

    @staticmethod
    def _calc_indices() -> Self.Indices:
        var result = Self.Indices(fill=Self.SegmentIndicesAggregate(fill={0, 0}))
        var offset = 0
        for y in range(Self.size):
            for x in range(Self.size - Self.win_stones + 1):
                for n in range(Self.win_stones):
                    var idx = y * Self.size + x + n
                    if result[idx][0].end == 0:
                        result[idx][0] = {offset, offset + 1}
                    else:
                        result[idx][0].end += 1
                offset += 1

        for x in range(Self.size):
            for y in range(Self.size - Self.win_stones + 1):
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x
                    if result[idx][1].end == 0:
                        result[idx][1] = {offset, offset + 1}
                    else:
                        result[idx][1].end += 1
                offset += 1

        for a in range(Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = a + b
                var y = b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x + n
                    if result[idx][2].end == 0:
                        result[idx][2] = {offset, offset + 1}
                    else:
                        result[idx][2].end += 1
                offset += 1

        for a in range(1, Self.size - Self.win_stones + 1):
            for b in range(a, Self.size - Self.win_stones + 1):
                var x = b - a
                var y = b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x + n
                    if result[idx][2].end == 0:
                        result[idx][2] = {offset, offset + 1}
                    else:
                        result[idx][2].end += 1
                offset += 1

        for a in range(Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = Self.size - a - b - 1
                var y = b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x - n
                    if result[idx][3].end == 0:
                        result[idx][3] = {offset, offset + 1}
                    else:
                        result[idx][3].end += 1
                offset += 1

        for a in range(1, Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = Self.size - b - 1
                var y = a + b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x - n
                    if result[idx][3].end == 0:
                        result[idx][3] = {offset, offset + 1}
                    else:
                        result[idx][3].end += 1
                offset += 1

        return result

    def write_to[W: Writer](self, mut writer: W):
        try:
            self.write(writer)
        except:
            pass

    def write[W: Writer](self, mut writer: W) raises:
        writer.write("\n  ")

        for i in range(Self.size):
            writer.write(t" {chr(i + ord('a'))}")
        writer.write("\n")

        for y in range(Self.size):
            writer.write(String(y + 1).ascii_rjust(2))
            for x in range(Self.size):
                var stone = self[x, y]
                if stone == Stone.black:
                    writer.write(" X") if x == 0 else writer.write("─X")
                elif stone == Stone.white:
                    writer.write(" O") if x == 0 else writer.write("─O")
                elif stone == Stone.none:
                    if y == 0:
                        if x == 0:
                            writer.write(" ┌")
                        elif x == Self.size - 1:
                            writer.write("─┐")
                        else:
                            writer.write("─┬")
                    elif y == Self.size - 1:
                        if x == 0:
                            writer.write(" └")
                        elif x == Self.size - 1:
                            writer.write("─┘")
                        else:
                            writer.write("─┴")
                    else:
                        if x == 0:
                            writer.write(" ├")
                        elif x == Self.size - 1:
                            writer.write("─┤")
                        else:
                            writer.write("─┼")
                else:
                    assert False
            writer.write(String(y + 1).ascii_rjust(3), "\n")

        writer.write("  ")

        for i in range(Self.size):
            writer.write(t" {chr(i + ord('a'))}")
        writer.write("\n")


comptime size = 19
comptime win_stones = 6
comptime B = Board[size, win_stones]


def main_1():
    var board = B()
    board.place_stone(Place(9, 9), Stone.black)
    print(board)


def main():
    print(t" segments: {B._calc_n_segments()}")
    var indices = B._calc_indices()
    for i in range(B.size * B.size):
        if i % size == 0:
            print()
        print(
            t"idx={String(i).ascii_rjust(3)} [{String(i % size).ascii_rjust(2)}:{String(i / size).ascii_rjust(2)}]",
            end="",
        )
        ref index_range = indices[i]
        for j in range(4):
            ref segment_indices = index_range[j]
            print(t" | {segment_indices.end - segment_indices.start} {String(segment_indices.start).ascii_rjust(4)}", end="")
        print()
