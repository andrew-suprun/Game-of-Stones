from hashlib.hasher import Hasher
from memory import memcpy

from score import Score
from heap import heap_add

comptime first = 0
comptime second = 1
comptime Scores = SIMD[DType.float32, 2]
comptime Stones = SIMD[DType.int64, 2]


@fieldwise_init
struct PlaceScores(ImplicitlyCopyable, TrivialRegisterType):
    var offset: Int
    var scores: Scores


@fieldwise_init
struct ScoreMark(ImplicitlyCopyable, TrivialRegisterType):
    var place: Place
    var score: Score
    var history_idx: Int


@fieldwise_init
struct Place(Comparable, Copyable, Defaultable, Stringable, TrivialRegisterType, Writable):
    var x: Int8
    var y: Int8

    fn __init__(out self):
        self.x = -1
        self.y = -1

    @implicit
    fn __init__(out self, place: String) raises:
        self.x = ord(place[byte=0]) - ord("a")
        self.y = Int(String(place)[1:]) - 1

    fn __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y

    fn __lt__(self, other: Self) -> Bool:
        return self.x < other.x or self.x == other.x and self.y < other.y

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(chr(Int(self.x) + ord("a")), self.y + 1)


struct Board[values: List[Float32], size: Int, win_stones: Int](Copyable, Stringable, Writable):
    comptime empty = Int8(0)
    comptime black = Int8(1)
    comptime white = Int8(Self.win_stones)

    var _places: InlineArray[Int8, Self.size * Self.size]
    var _scores: InlineArray[Scores, Self.size * Self.size]
    var _score: Score
    var _value_table: List[List[Scores]]
    var _history: List[PlaceScores]
    var _history_indices: List[ScoreMark]

    fn __init__(out self):
        self._places = InlineArray[Int8, Self.size * Self.size](fill=0)
        self._scores = InlineArray[Scores, Self.size * Self.size](uninitialized=True)
        self._score = 0
        self._value_table = _calc_value_table[Self.win_stones, Self.values]()
        self._history = List[PlaceScores]()
        self._history_indices = List[ScoreMark]()

        for y in range(Self.size):
            var v = 1 + min(Self.win_stones - 1, y, Self.size - 1 - y, Self.size - Self.win_stones)
            for x in range(Self.size):
                var h = 1 + min(Self.win_stones - 1, x, Self.size - 1 - x, Self.size - Self.win_stones)
                var m = 1 + min(x, y, Self.size - 1 - x, Self.size - 1 - y, Self.size - Self.win_stones)
                var t1 = max(0, min(Self.win_stones, m, Self.size - Self.win_stones + 1 - y + x, Self.size - Self.win_stones + 1 - x + y))
                var t2 = max(0, min(Self.win_stones, m, 2 * Self.size - 1 - Self.win_stones + 1 - y - x, x + y - Self.win_stones + 1 + 1))
                var total = v + h + t1 + t2
                self.setvalues(Place(x, y), Scores(total, total))

    fn place_stone(mut self, place: Place, turn: Int):
        self._history_indices.append(ScoreMark(place, self._score, len(self._history)))

        var x = Int(place.x)
        var y = Int(place.y)

        if turn == first:
            self._score += self.score(place, first)
        else:
            self._score -= self.score(place, second)

        var x_start = max(0, x - Self.win_stones + 1)
        var x_end = min(x + Self.win_stones, Self.size) - Self.win_stones + 1
        var n = x_end - x_start
        self._update_row(turn, y * Self.size + x_start, 1, n)

        var y_start = max(0, y - Self.win_stones + 1)
        var y_end = min(y + Self.win_stones, Self.size) - Self.win_stones + 1
        n = y_end - y_start
        self._update_row(turn, y_start * Self.size + x, Self.size, n)

        var m = 1 + min(x, y, Self.size - 1 - x, Self.size - 1 - y)

        n = min(Self.win_stones, m, Self.size - Self.win_stones + 1 - y + x, Self.size - Self.win_stones + 1 - x + y)
        if n > 0:
            var mn = min(x, y, Self.win_stones - 1)
            var x_start = x - mn
            var y_start = y - mn
            self._update_row(turn, y_start * Self.size + x_start, Self.size + 1, n)

        n = min(Self.win_stones, m, 2 * Self.size - Self.win_stones - y - x, x + y - Self.win_stones + 2)
        if n > 0:
            var mn = min(Self.size - 1 - x, y, Self.win_stones - 1)
            var x_start = x + mn
            var y_start = y - mn
            self._update_row(turn, y_start * Self.size + x_start, Self.size - 1, n)

        if turn == first:
            self[x, y] = Self.black
        else:
            self[x, y] = Self.white

    @always_inline
    fn _update_row(mut self, turn: Int, start: Int, delta: Int, n: Int):
        ref scores = self._value_table[turn]

        var offset = start
        var stones = Int8(0)

        for i in range(start, start + delta * (Self.win_stones - 1 + n), delta):
            self._history.append(PlaceScores(i, self._scores[i]))

        for _ in range(n + Self.win_stones - 1):
            offset += delta

        offset = start

        @parameter
        for i in range(Self.win_stones - 1):
            stones += self._places[offset + i * delta]

        for _ in range(n):
            stones += self._places[offset + delta * (Self.win_stones - 1)]
            var scores = scores[stones]
            if scores[0] != 0 or scores[1] != 0:

                @parameter
                for j in range(Self.win_stones):
                    self._scores[offset + j * delta] += scores
            stones -= self._places[offset]
            offset += delta

    fn remove_stone(mut self):
        var idx = self._history_indices.pop()
        self[Int(idx.place.x), Int(idx.place.y)] = self.empty
        self._score = idx.score
        for i in range(len(self._history)-1, idx.history_idx-1, -1):
            var h_scores = self._history[i]
            self._scores[h_scores.offset] = h_scores.scores
        self._history.shrink(idx.history_idx)

    fn places(self, turn: Int, mut places: List[Place]):
        @parameter
        fn less_first(a: Place, b: Place, out r: Bool):
            r = self.score(a, first) < self.score(b, first)

        @parameter
        fn less_second(a: Place, b: Place, out r: Bool):
            r = self.score(a, second) < self.score(b, second)

        if turn == first:
            for y in range(Self.size):
                for x in range(Self.size):
                    if self[x, y] == self.empty:
                        heap_add[less_first](Place(x, y), places)
        else:
            for y in range(Self.size):
                for x in range(Self.size):
                    if self[x, y] == self.empty:
                        heap_add[less_second](Place(x, y), places)

    fn __getitem__(self, x: Int, y: Int, out result: Int8):
        result = self._places[y * Self.size + x]

    fn __setitem__(mut self, x: Int, y: Int, value: Int8):
        self._places[y * Self.size + x] = value

    fn score(self, place: Place, turn: Int) -> Score:
        return Score(self._scores[Int(place.y) * Self.size + Int(place.x)][turn])

    fn setvalues(mut self, place: Place, value: Scores):
        self._scores[Int(place.y) * Self.size + Int(place.x)] = value

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        try:
            self.write(writer)
        except:
            pass

    fn write[W: Writer](self, mut writer: W) raises:
        writer.write("\n  ")

        for i in range(Self.size):
            writer.write(String.format(" {}", chr(i + ord("a"))))
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
        for i in range(Self.size):
            str += String.format("    {} ", chr(i + ord("a")))
        str += "│\n"
        str += "───┼" + "──────" * Self.size + "┼───\n"
        for y in range(Self.size):
            str += String(y + 1).ascii_rjust(2) + " │"
            for x in range(Self.size):
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
                        str += String(Int(value.value)).ascii_rjust(5, " ") + " "
            str += "│ " + String(y + 1).ascii_rjust(2) + "\n"
        str += "───┼" + "──────" * Self.size + "┼───"
        if not table_idx:
            str += "\n   │"
            for i in range(Self.size):
                str += String.format("    {} ", chr(i + ord("a")))
            str += "│\n"

    fn board_value(self, scores: List[Float32]) -> Score:
        var value = Score(0)
        for y in range(Self.size):
            var stones = Int8(0)
            for x in range(Self.win_stones - 1):
                stones += self[x, y]
            for x in range(Self.size - Self.win_stones + 1):
                stones += self[x + Self.win_stones - 1, y]
                value += self._calc_value(stones, scores)
                stones -= self[x, y]

        for x in range(Self.size):
            var stones = Int8(0)
            for y in range(Self.win_stones - 1):
                stones += self[x, y]
            for y in range(Self.size - Self.win_stones + 1):
                stones += self[x, y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[x, y]

        for y in range(Self.size - Self.win_stones + 1):
            var stones = Int8(0)
            for x in range(Self.win_stones - 1):
                stones += self[x, y + x]
            for x in range(Self.size - Self.win_stones + 1 - y):
                stones += self[x + Self.win_stones - 1, x + y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[x, x + y]

        for x in range(1, Self.size - Self.win_stones + 1):
            var stones = Int8(0)
            for y in range(Self.win_stones - 1):
                stones += self[x + y, y]
            for y in range(Self.size - Self.win_stones + 1 - x):
                stones += self[x + y + Self.win_stones - 1, y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[x + y, y]

        for y in range(Self.size - Self.win_stones + 1):
            var stones = Int8(0)
            for x in range(Self.win_stones - 1):
                stones += self[Self.size - 1 - x, x + y]
            for x in range(Self.size - Self.win_stones + 1 - y):
                stones += self[Self.size - 1 - x - Self.win_stones + 1, x + y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[Self.size - 1 - x, x + y]

        for x in range(1, Self.size - Self.win_stones + 1):
            var stones = Int8(0)
            for y in range(Self.win_stones - 1):
                stones += self[Self.size - 1 - x - y, y]
            for y in range(Self.size - Self.win_stones + 1 - x):
                stones += self[Self.size - Self.win_stones - x - y, y + Self.win_stones - 1]
                value += self._calc_value(stones, scores)
                stones -= self[Self.size - 1 - x - y, y]
        return value

    fn _calc_value(self, stones: Int8, scores: List[Float32]) -> Score:
        var black = stones % Self.win_stones
        var white = stones // Self.win_stones
        if white == 0:
            return Score(scores[black])
        elif black == 0:
            return Score(-scores[white])
        return 0

    fn max_score(self, player: Int) -> Score:
        var max_scores = self._scores[0]

        for y in range(Self.size):
            for x in range(Self.size):
                if self[x, y] == self.empty:
                    max_scores = max(max_scores, self._scores[y * Self.size + x])

        return Score(max_scores[player])


fn _calc_value_table[win_stones: Int, scores: List[Float32]]() -> List[List[Scores]]:
    comptime result_size = win_stones * win_stones + 1

    var s = materialize[scores]()
    s.append(Float32.MAX)
    var v2: List[Scores] = [Scores(1, -1)]
    for i in range(win_stones - 1):
        v2.append(Scores(s[i + 2] - s[i + 1], -s[i + 1]))
    var result = [List[Scores](length=result_size, fill=0), List[Scores](length=result_size, fill=0)]

    for i in range(win_stones - 1):
        result[0][i * win_stones] = Scores(v2[i][1], -v2[i][0])
        result[0][i] = Scores(v2[i + 1][0] - v2[i][0], v2[i][1] - v2[i + 1][1])
        result[1][i] = Scores(-v2[i][0], v2[i][1])
        result[1][i * win_stones] = Scores(v2[i][1] - v2[i + 1][1], v2[i + 1][0] - v2[i][0])
    return result^
