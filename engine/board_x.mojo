comptime black = 0
comptime white = 1
comptime empty = 2


struct PlaceX(Comparable, Copyable, Defaultable, TrivialRegisterPassable, Writable):
    var x: Int
    var y: Int

    def __init__(out self):
        self.x = -1
        self.y = -1

    def __init__(out self, x: Int, y: Int):
        self.x = x
        self.y = y

    @implicit
    def __init__(out self, place: String) raises:
        self.x = Int(ord(place[byte=0]) - ord("a"))
        self.y = Int(place[byte=1:]) - 1

    def __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y

    def __lt__(self, other: Self) -> Bool:
        return self.x < other.x or self.x == other.x and self.y < other.y

    def write_to[W: Writer](self, mut writer: W):
        writer.write(chr(self.x + ord("a")), self.y + 1)


@fieldwise_init
struct StoneCounts(ImplicitlyCopyable, Writable):
    var max_stones: Int
    var n_segments: Int

    def write_to[W: Writer](self, mut writer: W):
        if self.max_stones == 0:
            writer.write("-")
        else:
            writer.write(t"{self.max_stones} ({self.n_segments})")


struct BoardX[size: Int, win_stones: Int](Writable):
    comptime PlaceStoneCounts = InlineArray[StoneCounts, 4]
    comptime PlaceScores = InlineArray[Self.PlaceStoneCounts, 2]

    var _places: InlineArray[Int8, Self.size**2]

    def __init__(out self):
        self._places = InlineArray[Int8, Self.size**2](fill=empty)

    def __getitem__(self, x: Int, y: Int) -> Int:
        return Int(self._places[y * Self.size + x])

    def __setitem__(mut self, x: Int, y: Int, value: Int):
        self._places[y * Self.size + x] = Int8(value)

    def place_stone(mut self, place: PlaceX, color: Int):
        self._places[place.y * Self.size + place.x] = Int8(color)

    def score_place(self, place: PlaceX, mut scores: Self.PlaceScores):
        var x = place.x
        var y = place.y
        var x_start = max(0, x - Self.win_stones + 1)
        var x_end = min(x + Self.win_stones, Self.size) - Self.win_stones + 1
        var n = x_end - x_start
        self._score_row(y * Self.size + x_start, 1, n, 0, scores)

        var y_start = max(0, y - Self.win_stones + 1)
        var y_end = min(y + Self.win_stones, Self.size) - Self.win_stones + 1
        n = y_end - y_start
        self._score_row(y_start * Self.size + x, Self.size, n, 1, scores)

        var m = 1 + min(x, y, Self.size - 1 - x, Self.size - 1 - y)

        var upper_bound = Self.size - Self.win_stones + 1
        n = min(Self.win_stones, m, upper_bound - y + x, upper_bound - x + y)
        if n > 0:
            var mn = min(x, y, Self.win_stones - 1)
            var x_start = x - mn
            var y_start = y - mn
            self._score_row(y_start * Self.size + x_start, Self.size + 1, n, 2, scores)

        n = min(Self.win_stones, m, 2 * Self.size - Self.win_stones - y - x, x + y - Self.win_stones + 2)
        if n > 0:
            var mn = min(Self.size - 1 - x, y, Self.win_stones - 1)
            var x_start = x + mn
            var y_start = y - mn
            self._score_row(y_start * Self.size + x_start, Self.size - 1, n, 3, scores)

    def _score_row(self, start: Int, delta: Int, n: Int, d: Int, mut scores: Self.PlaceScores):
        # print(t"---- start {start} delta {delta} n {n} d {d}")
        var offset = start

        var stone_counts = InlineArray[Int, 3](fill=0)
        var black_max_stones = 0
        var black_n_segments = 0
        var white_max_stones = 0
        var white_n_segments = 0

        comptime for i in range(Self.win_stones - 1):
            var stone = self._places[offset + i * delta]
            stone_counts[stone] += 1
            # print(t"1: offset {offset + i * delta} stone {stone}  stone_counts {stone_counts}")

        for _ in range(n):
            var stone = self._places[offset + delta * (Self.win_stones - 1)]
            stone_counts[Int(stone)] += 1
            # print(t"2: offset {offset + delta * (Self.win_stones - 1)} stone {stone}  stone_counts {stone_counts}")
            if stone_counts[white] == 0:
                if black_max_stones < stone_counts[black]:
                    black_max_stones = stone_counts[black]
                    black_n_segments = 1
                elif black_max_stones == stone_counts[black]:
                    black_n_segments += 1
            if stone_counts[black] == 0:
                if white_max_stones < stone_counts[white]:
                    white_max_stones = stone_counts[white]
                    white_n_segments = 1
                elif white_max_stones == stone_counts[white]:
                    white_n_segments += 1

            # print(t"black_max_stones {black_max_stones} black_n_segments {black_n_segments}")
            # print(t"white_max_stones {white_max_stones} white_n_segments {white_n_segments}")

            stone_counts[Int(self._places[offset])] -= 1
            offset += delta

        scores[black][d] = StoneCounts(black_max_stones, black_n_segments)
        scores[white][d] = StoneCounts(white_max_stones, white_n_segments)

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
                if stone == black:
                    writer.write(" X") if x == 0 else writer.write("─X")
                elif stone == white:
                    writer.write(" O") if x == 0 else writer.write("─O")
                elif stone == empty:
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


def main_x() raises:
    comptime B = Board[19, 6]
    var b = B()
    b.place_stone("j10", 0)
    b.place_stone("i10", 1)
    b.place_stone("j9", 1)
    b.place_stone("h11", 0)
    b.place_stone("i11", 0)
    print(b)
    var score = B.PlaceScores(fill=B.PlaceStoneCounts(fill={0, 0}))
    b.score_place("k9", score)
    print(t"black: {score[black]} | white: {score[white]}")
