from hashlib.hasher import Hasher
from builtin.sort import sort
from utils.numerics import isinf
from memory import memcpy

from score import Score
from heap import heap_add

alias first = 0
alias second = 1
alias Scores = SIMD[DType.float32, 2]
alias Stones = SIMD[DType.int64, 2]


@fieldwise_init
@register_passable("trivial")
struct Place(Copyable, Defaultable, EqualityComparable, Hashable, LessThanComparable, Movable, Stringable, Writable):
    var x: Int8
    var y: Int8

    fn __init__(out self):
        self.x = -1
        self.y = -1

    @implicit
    fn __init__(out self, place: String) raises:
        self.x = ord(place[0]) - ord("a")
        self.y = Int(String(place)[1:]) - 1

    fn __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y

    fn __ne__(self, other: Self) -> Bool:
        return self.x != other.x or self.y != other.y

    fn __lt__(self, other: Self) -> Bool:
        return self.x < other.x or self.x == other.x and self.y < other.y

    fn __hash__[H: Hasher](self, mut hasher: H):
        hasher.update(self.x)
        hasher.update(self.y)

    fn connected_to[win_stones: Int](self, other: Place) -> Bool:
        if (
            self.x >= other.x + win_stones
            or other.x >= self.x + win_stones
            or self.y >= other.y + win_stones
            or other.y >= self.y + win_stones
        ):
            return False
        if self.x == other.x or self.y == other.y:
            return True
        if self.x + self.y == other.x + other.y:
            return True
        if self.x + other.y == self.y + other.x:
            return True
        return False

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(chr(Int(self.x) + ord("a")), self.y + 1)


struct Board[size: Int, values: List[Float32], win_stones: Int](ExplicitlyCopyable, Stringable, Writable):
    alias empty = Int8(0)
    alias black = Int8(1)
    alias white = Int8(win_stones)
    alias value_table = _value_table[win_stones, values]()

    var _places: InlineArray[Int8, size * size]
    var _scores: InlineArray[Scores, size * size]
    var _score: Score

    fn __init__(out self):
        self._places = InlineArray[Int8, size * size](fill=0)
        self._scores = InlineArray[Scores, size * size](uninitialized=True)
        self._score = 0

        for y in range(size):
            var v = 1 + min(win_stones - 1, y, size - 1 - y, size - win_stones)
            for x in range(size):
                var h = 1 + min(win_stones - 1, x, size - 1 - x, size - win_stones)
                var m = 1 + min(x, y, size - 1 - x, size - 1 - y, size - win_stones)
                var t1 = max(0, min(win_stones, m, size - win_stones + 1 - y + x, size - win_stones + 1 - x + y))
                var t2 = max(0, min(win_stones, m, 2 * size - 1 - win_stones + 1 - y - x, x + y - win_stones + 1 + 1))
                var total = v + h + t1 + t2
                self.setvalues(Place(x, y), Scores(total, total))

    fn __copyinit__(out self, existing: Self, /):
        self._places = InlineArray[Int8, size * size](uninitialized=True)
        memcpy(self._places.unsafe_ptr(), existing._places.unsafe_ptr(), size * size)

        self._scores = InlineArray[Scores, size * size](uninitialized=True)
        memcpy(self._scores.unsafe_ptr(), existing._scores.unsafe_ptr(), size * size)

        self._score = existing._score

    fn copy(self) -> Self:
        return self

    fn place_stone(mut self, place: Place, turn: Int):
        var scores = self.value_table[turn]

        var x = Int(place.x)
        var y = Int(place.y)

        if turn == first:
            self._score += self.score(place, first)
        else:
            self._score -= self.score(place, second)

        var x_start = max(0, x - win_stones + 1)
        var x_end = min(x + win_stones, size) - win_stones + 1
        var n = x_end - x_start
        self._update_row(y * size + x_start, 1, n, scores)

        var y_start = max(0, y - win_stones + 1)
        var y_end = min(y + win_stones, size) - win_stones + 1
        n = y_end - y_start
        self._update_row(y_start * size + x, size, n, scores)

        var m = 1 + min(x, y, size - 1 - x, size - 1 - y)

        n = min(win_stones, m, size - win_stones + 1 - y + x, size - win_stones + 1 - x + y)
        if n > 0:
            var mn = min(x, y, win_stones - 1)
            var x_start = x - mn
            var y_start = y - mn
            self._update_row(y_start * size + x_start, size + 1, n, scores)

        n = min(win_stones, m, 2 * size - win_stones - y - x, x + y - win_stones + 2)
        if n > 0:
            var mn = min(size - 1 - x, y, win_stones - 1)
            var x_start = x + mn
            var y_start = y - mn
            self._update_row(y_start * size + x_start, size - 1, n, scores)

        if turn == first:
            self[x, y] = Self.black
        else:
            self[x, y] = Self.white

    fn _update_row(mut self, start: Int, delta: Int, n: Int, scores: InlineArray[Scores, win_stones * win_stones + 1]):
        var offset = start
        var stones = Int8(0)

        @parameter
        for i in range(win_stones - 1):
            stones += self._places[offset + i * delta]

        for _ in range(n):
            stones += self._places[offset + delta * (win_stones - 1)]
            var scores = scores[stones]
            if scores[0] != 0 or scores[1] != 0:

                @parameter
                for j in range(win_stones):
                    self._scores[offset + j * delta] += scores
            stones -= self._places[offset]
            offset += delta

    fn places(self, turn: Int, mut places: List[Place]):
        @parameter
        fn less_first(a: Place, b: Place, out r: Bool):
            r = self.score(a, first) < self.score(b, first)

        @parameter
        fn less_second(a: Place, b: Place, out r: Bool):
            r = self.score(a, second) < self.score(b, second)

        if turn == first:
            for y in range(size):
                for x in range(size):
                    if self[x, y] == self.empty:
                        heap_add[less_first](Place(x, y), places)
        else:
            for y in range(size):
                for x in range(size):
                    if self[x, y] == self.empty:
                        heap_add[less_second](Place(x, y), places)

    fn __getitem__(self, x: Int, y: Int, out result: Int8):
        result = self._places[y * size + x]

    fn __setitem__(mut self, x: Int, y: Int, value: Int8):
        self._places[y * size + x] = value

    fn score(self, place: Place, turn: Int) -> Score:
        return Score(self._scores[Int(place.y) * size + Int(place.x)][turn])

    fn setvalues(mut self, place: Place, value: Scores):
        self._scores[Int(place.y) * size + Int(place.x)] = value

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        try:
            self.write(writer)
        except:
            pass

    fn write[W: Writer](self, mut writer: W) raises:
        writer.write("\n  ")

        for i in range(size):
            writer.write(String.format(" {}", chr(i + ord("a"))))
        writer.write("\n")

        for y in range(size):
            writer.write(String(y + 1).rjust(2))
            for x in range(size):
                var stone = self[x, y]
                if stone == Self.black:
                    writer.write(" X") if x == 0 else writer.write("─X")
                elif stone == Self.white:
                    writer.write(" O") if x == 0 else writer.write("─O")
                else:
                    if y == 0:
                        if x == 0:
                            writer.write(" ┌")
                        elif x == size - 1:
                            writer.write("─┐")
                        else:
                            writer.write("─┬")
                    elif y == size - 1:
                        if x == 0:
                            writer.write(" └")
                        elif x == size - 1:
                            writer.write("─┘")
                        else:
                            writer.write("─┴")
                    else:
                        if x == 0:
                            writer.write(" ├")
                        elif x == size - 1:
                            writer.write("─┤")
                        else:
                            writer.write("─┼")
            writer.write(String(y + 1).rjust(3), "\n")

        writer.write("  ")

        for i in range(size):
            writer.write(String.format(" {}", chr(i + ord("a"))))
        writer.write("\n")

    fn str_scores(self, out str: String):
        try:
            str = self.str_scores_raises(0)
            str += self.str_scores_raises(1)
        except:
            str = ""

    fn str_scores_raises(self, table_idx: Int, out str: String) raises:
        str = "\n   │"
        for i in range(size):
            str += String.format("    {} ", chr(i + ord("a")))
        str += "│\n"
        str += "───┼" + "──────" * size + "┼───\n"
        for y in range(size):
            str += String(y + 1).rjust(2) + " │"
            for x in range(size):
                var stone = self[x, y]
                if stone == Self.black:
                    str += "    X "
                elif stone == Self.white:
                    str += "    O "
                else:
                    var value = self.score(Place(x, y), table_idx)
                    if value.is_win():
                        str += "  Win "
                    else:
                        str += String(Int(value.value)).rjust(5, " ") + " "
            str += "│ " + String(y + 1).rjust(2) + "\n"
        str += "───┼" + "──────" * size + "┼───"
        if not table_idx:
            str += "\n   │"
            for i in range(size):
                str += String.format("    {} ", chr(i + ord("a")))
            str += "│\n"

    fn board_value(self, scores: List[Float32]) -> Score:
        var value = Score(0)
        for y in range(size):
            var stones = Int8(0)
            for x in range(win_stones - 1):
                stones += self[x, y]
            for x in range(size - win_stones + 1):
                stones += self[x + win_stones - 1, y]
                value += self._calc_value(stones, scores)
                stones -= self[x, y]

        for x in range(size):
            var stones = Int8(0)
            for y in range(win_stones - 1):
                stones += self[x, y]
            for y in range(size - win_stones + 1):
                stones += self[x, y + win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[x, y]

        for y in range(size - win_stones + 1):
            var stones = Int8(0)
            for x in range(win_stones - 1):
                stones += self[x, y + x]
            for x in range(size - win_stones + 1 - y):
                stones += self[x + win_stones - 1, x + y + win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[x, x + y]

        for x in range(1, size - win_stones + 1):
            var stones = Int8(0)
            for y in range(win_stones - 1):
                stones += self[x + y, y]
            for y in range(size - win_stones + 1 - x):
                stones += self[x + y + win_stones - 1, y + win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[x + y, y]

        for y in range(size - win_stones + 1):
            var stones = Int8(0)
            for x in range(win_stones - 1):
                stones += self[size - 1 - x, x + y]
            for x in range(size - win_stones + 1 - y):
                stones += self[size - 1 - x - win_stones + 1, x + y + win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[size - 1 - x, x + y]

        for x in range(1, size - win_stones + 1):
            var stones = Int8(0)
            for y in range(win_stones - 1):
                stones += self[size - 1 - x - y, y]
            for y in range(size - win_stones + 1 - x):
                stones += self[size - win_stones - x - y, y + win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[size - 1 - x - y, y]
        return value

    fn _calc_value(self, stones: Int8, scores: List[Float32]) -> Score:
        var black = stones % win_stones
        var white = stones // win_stones
        if white == 0:
            return Score(scores[black])
        elif black == 0:
            return Score(-scores[white])
        return 0

    fn max_score(self, player: Int) -> Score:
        var max_scores = self._scores[0]

        for y in range(size):
            for x in range(size):
                if self[x, y] == self.empty:
                    max_scores = max(max_scores, self._scores[y * size + x])

        return Score(max_scores[player])


fn _value_table[win_stones: Int, scores: List[Float32]]() -> InlineArray[InlineArray[Scores, win_stones * win_stones + 1], 2]:
    alias result_size = win_stones * win_stones + 1

    var s = scores
    s.append(Float32.MAX)
    v2 = List[Scores](Scores(1, -1))
    for i in range(win_stones - 1):
        v2.append(Scores(s[i + 2] - s[i + 1], -s[i + 1]))
    var result = InlineArray[InlineArray[Scores, result_size], 2](fill=InlineArray[Scores, result_size](fill=0))

    for i in range(win_stones - 1):
        result[0][i * win_stones] = Scores(v2[i][1], -v2[i][0])
        result[0][i] = Scores(v2[i + 1][0] - v2[i][0], v2[i][1] - v2[i + 1][1])
        result[1][i] = Scores(-v2[i][0], v2[i][1])
        result[1][i * win_stones] = Scores(v2[i][1] - v2[i + 1][1], v2[i + 1][0] - v2[i][0])
    return result
