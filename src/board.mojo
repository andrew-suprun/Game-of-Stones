from std.sys.defines import get_defined_string
from std.memory import memcpy

from score import Score, Win
from heap import heap_add

comptime logging_level = get_defined_string["LOGGING_LEVEL", "NOTSET"]()
comptime TRACE = logging_level == "TRACE"
comptime DEBUG = logging_level == "DEBUG" or TRACE

comptime first = 0
comptime second = 1
comptime Scores = SIMD[Score.dtype, 2]


struct Place(Comparable, Copyable, Defaultable, TrivialRegisterPassable, Writable):
    var x: Int8
    var y: Int8

    def __init__(out self):
        self.x = -1
        self.y = -1

    def __init__(out self, x: Int, y: Int):
        self.x = Int8(x)
        self.y = Int8(y)

    @implicit
    def __init__(out self, place: String) raises:
        self.x = Int8(ord(place[byte=0]) - ord("a"))
        self.y = Int8(Int(place[byte=1:]) - 1)

    def __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y

    def __lt__(self, other: Self) -> Bool:
        return self.x < other.x or self.x == other.x and self.y < other.y

    def write_to[W: Writer](self, mut writer: W):
        writer.write(chr(Int(self.x) + ord("a")), self.y + 1)


@fieldwise_init
struct PlaceScore(TrivialRegisterPassable, Writable):
    var place: Place
    var score: Score


def less(a: PlaceScore, b: PlaceScore) -> Bool:
    return a.score < b.score


struct Board[size: Int, values: List[Score], win_stones: Int](Copyable, Writable):
    comptime empty = 0
    comptime black = 1
    comptime white = Self.win_stones
    comptime value_table = _calc_value_table[Self.win_stones, Self.values]()

    var _places: InlineArray[Int8, Self.size * Self.size]
    var _scores: InlineArray[Scores, Self.size * Self.size]
    var _score: Score

    def __init__(out self):
        self._places = InlineArray[Int8, Self.size * Self.size](fill=0)
        self._scores = InlineArray[Scores, Self.size * Self.size](uninitialized=True)
        self._score = 0

        for y in range(Self.size):
            var v = 1 + min(Self.win_stones - 1, y, Self.size - 1 - y, Self.size - Self.win_stones)
            for x in range(Self.size):
                var h = 1 + min(Self.win_stones - 1, x, Self.size - 1 - x, Self.size - Self.win_stones)
                var m = 1 + min(x, y, Self.size - 1 - x, Self.size - 1 - y, Self.size - Self.win_stones)
                var t1 = max(
                    0,
                    min(
                        Self.win_stones,
                        m,
                        Self.size - Self.win_stones + 1 - y + x,
                        Self.size - Self.win_stones + 1 - x + y,
                    ),
                )
                var t2 = max(
                    0,
                    min(
                        Self.win_stones,
                        m,
                        2 * Self.size - 1 - Self.win_stones + 1 - y - x,
                        x + y - Self.win_stones + 1 + 1,
                    ),
                )
                var total = Score(v + h + t1 + t2)
                self._scores[y * Self.size + x] = [total, total]

    def place_stone(mut self, place: Place, turn: Int):
        ref value_table = materialize[self.value_table]()
        ref scores = value_table[turn]

        var x = Int(place.x)
        var y = Int(place.y)

        if turn == first:
            self._score += self.score(place, first)
        else:
            self._score -= self.score(place, second)

        var x_start = max(0, x - Self.win_stones + 1)
        var x_end = min(x + Self.win_stones, Self.size) - Self.win_stones + 1
        var n = x_end - x_start
        self._update_row(y * Self.size + x_start, 1, n, scores)

        var y_start = max(0, y - Self.win_stones + 1)
        var y_end = min(y + Self.win_stones, Self.size) - Self.win_stones + 1
        n = y_end - y_start
        self._update_row(y_start * Self.size + x, Self.size, n, scores)

        var m = 1 + min(x, y, Self.size - 1 - x, Self.size - 1 - y)

        var upper_bound = Self.size - Self.win_stones + 1
        n = min(Self.win_stones, m, upper_bound - y + x, upper_bound - x + y)
        if n > 0:
            var mn = min(x, y, Self.win_stones - 1)
            var x_start = x - mn
            var y_start = y - mn
            self._update_row(y_start * Self.size + x_start, Self.size + 1, n, scores)

        n = min(Self.win_stones, m, 2 * Self.size - Self.win_stones - y - x, x + y - Self.win_stones + 2)
        if n > 0:
            var mn = min(Self.size - 1 - x, y, Self.win_stones - 1)
            var x_start = x + mn
            var y_start = y - mn
            self._update_row(y_start * Self.size + x_start, Self.size - 1, n, scores)

        if turn == first:
            self[x, y] = Self.black
        else:
            self[x, y] = Self.white

    def _update_row(
        mut self, start: Int, delta: Int, n: Int, scores: InlineArray[Scores, Self.win_stones * Self.win_stones + 1]
    ):
        var offset = start
        var stones = Int8(0)

        for _ in range(n + Self.win_stones - 1):
            offset += delta

        offset = start

        comptime for i in range(Self.win_stones - 1):
            stones += self._places[offset + i * delta]

        for _ in range(n):
            stones += self._places[offset + delta * (Self.win_stones - 1)]
            var scores = scores[stones]
            if scores[0] != 0 or scores[1] != 0:
                comptime for j in range(Self.win_stones):
                    self._scores[offset + j * delta] += scores
            stones -= self._places[offset]
            offset += delta

    def places(self, turn: Int, mut places: List[PlaceScore]):
        if turn == first:
            for y in range(Self.size):
                for x in range(Self.size):
                    if self[x, y] == self.empty:
                        var place = Place(x, y)
                        heap_add[less](PlaceScore(place, self.score(place, first)), places)
        else:
            for y in range(Self.size):
                for x in range(Self.size):
                    if self[x, y] == self.empty:
                        var place = Place(x, y)
                        heap_add[less](PlaceScore(place, self.score(place, second)), places)

    def __getitem__(self, x: Int, y: Int) -> Int:
        return Int(self._places[y * Self.size + x])

    def __setitem__(mut self, x: Int, y: Int, value: Int):
        self._places[y * Self.size + x] = Int8(value)

    def score(mut self) -> Score:
        return self._score

    def score(self, place: Place, turn: Int) -> Score:
        return Score(self._scores[Int(place.y) * Self.size + Int(place.x)][turn])

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
                if stone == Self.black:
                    writer.write(" X") if x == 0 else writer.write("─X")
                elif stone == Self.white:
                    writer.write(" O") if x == 0 else writer.write("─O")
                else:
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
            writer.write(String(y + 1).ascii_rjust(3), "\n")

        writer.write("  ")

        for i in range(Self.size):
            writer.write(t" {chr(i + ord('a'))}")
        writer.write("\n")

    def str_scores(self, out str: String):
        try:
            str = self.str_scores_raises(0)
            str += self.str_scores_raises(1)
        except:
            str = ""

    def str_scores_raises(self, table_idx: Int, out str: String) raises:
        str = "\n   │"
        for i in range(Self.size):
            str += String(t"   {chr(i + ord('a'))} ")
        str += "│\n"
        str += "───┼" + "─────" * Self.size + "┼───\n"
        for y in range(Self.size):
            str += String(y + 1).ascii_rjust(2) + " │"
            for x in range(Self.size):
                var stone = self[x, y]
                if stone == Self.black:
                    str += "   X "
                elif stone == Self.white:
                    str += "   O "
                else:
                    var value = self.score(Place(x, y), table_idx)
                    str += String(Int(value)).ascii_rjust(4, " ") + " "
            str += "│ " + String(y + 1).ascii_rjust(2) + "\n"
        str += "───┼" + "─────" * Self.size + "┼───"
        str += "\n   │"
        for i in range(Self.size):
            str += String(t"   {chr(i + ord('a'))} ")
        str += "│\n"

    def board_value(self, scores: List[Score]) -> Score:
        var value = Score(0)
        for y in range(Self.size):
            var stones = 0
            for x in range(Self.win_stones - 1):
                stones += self[x, y]
            for x in range(Self.size - Self.win_stones + 1):
                stones += self[x + Self.win_stones - 1, y]
                value += self._calc_value(stones, scores)
                stones -= self[x, y]

        for x in range(Self.size):
            var stones = 0
            for y in range(Self.win_stones - 1):
                stones += self[x, y]
            for y in range(Self.size - Self.win_stones + 1):
                stones += self[x, y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[x, y]

        for y in range(Self.size - Self.win_stones + 1):
            var stones = 0
            for x in range(Self.win_stones - 1):
                stones += self[x, y + x]
            for x in range(Self.size - Self.win_stones + 1 - y):
                stones += self[x + Self.win_stones - 1, x + y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[x, x + y]

        for x in range(1, Self.size - Self.win_stones + 1):
            var stones = 0
            for y in range(Self.win_stones - 1):
                stones += self[x + y, y]
            for y in range(Self.size - Self.win_stones + 1 - x):
                stones += self[x + y + Self.win_stones - 1, y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[x + y, y]

        for y in range(Self.size - Self.win_stones + 1):
            var stones = 0
            for x in range(Self.win_stones - 1):
                stones += self[Self.size - 1 - x, x + y]
            for x in range(Self.size - Self.win_stones + 1 - y):
                stones += self[Self.size - 1 - x - Self.win_stones + 1, x + y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[Self.size - 1 - x, x + y]

        for x in range(1, Self.size - Self.win_stones + 1):
            var stones = 0
            for y in range(Self.win_stones - 1):
                stones += self[Self.size - 1 - x - y, y]
            for y in range(Self.size - Self.win_stones + 1 - x):
                stones += self[Self.size - Self.win_stones - x - y, y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[Self.size - 1 - x - y, y]
        return value

    def _calc_value(self, stones: Int, scores: List[Score]) -> Score:
        var black = Int(stones) % Self.win_stones
        var white = Int(stones) / Self.win_stones
        if white == 0:
            return Score(scores[black])
        elif black == 0:
            return Score(-scores[white])
        return 0

    def max_score(self, player: Int) -> Score:
        var max_score = self._scores[0][player]

        for i in range(Self.size * Self.size):
            if self._places[i] == Self.empty:
                max_score = max(max_score, self._scores[i][player])

        return max_score


def _calc_value_table[
    win_stones: Int, scores: List[Score]
]() -> InlineArray[InlineArray[Scores, win_stones * win_stones + 1], 2]:
    comptime result_size = win_stones * win_stones + 1

    var s = materialize[scores]()
    s.append(2 * Win)
    var v2: List[Scores] = [Scores(1, -1)]
    for i in range(win_stones - 1):
        v2.append(Scores(s[i + 2] - s[i + 1], -s[i + 1]))
    var result = InlineArray[InlineArray[Scores, result_size], 2](fill=InlineArray[Scores, result_size](fill=0))

    for i in range(win_stones - 1):
        result[0][i * win_stones] = Scores(v2[i][1], -v2[i][0])
        result[0][i] = Scores(v2[i + 1][0] - v2[i][0], v2[i][1] - v2[i + 1][1])
        result[1][i] = Scores(-v2[i][0], v2[i][1])
        result[1][i * win_stones] = Scores(v2[i][1] - v2[i + 1][1], v2[i + 1][0] - v2[i][0])
    return result^


def main():
    var board = Board[19, [0, 1, 5, 25, 125, 625], 6]()
    print(board)
    print(board.str_scores())
    var table = _calc_value_table[6, [0, 1, 5, 25, 125, 625]]()
    for side in range(2):
        for color in range(2):
            for y in range(6):
                for x in range(6):
                    print(table[side][y * 6 + x][color], "", end="")
                print()
            print()
    print()
