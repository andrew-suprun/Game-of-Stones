from memory import memcpy

from game import Score
from heap import heap_add

alias first = 0
alias second = 1
alias Scores = SIMD[DType.float32, 2]

@fieldwise_init
@register_passable("trivial")
struct Place(Copyable, Movable, EqualityComparable, Defaultable, Stringable, Writable):
    var x: Int8
    var y: Int8

    fn __init__(out self):
        self.x = 0
        self.y = 0

    @implicit
    fn __init__(out self, place: String) raises:
        self.x = ord(place[0]) - ord("a")
        self.y = Int(place[1:]) - 1

    @implicit
    fn __init__(out self, place: StringLiteral) raises:
        self.x = ord(place[0]) - ord("a")
        self.y = Int(String(place)[1:]) - 1

    fn __eq__(self, other: Self, out result: Bool):
        result = self.x == other.x and self.y == other.y

    fn __ne__(self, other: Self, out result: Bool):
        result = not (self == other)

    fn __str__(self, out result: String):
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(chr(Int(self.x) + ord("a")), self.y + 1)

struct Board[values: List[Score], size: Int, win_stones: Int, max_places: Int](Stringable, Writable):
    alias empty = Int8(0)
    alias black = Int8(1)
    alias white = Int8(win_stones)
    alias value_table = _value_table[win_stones, values]()

    var _places: InlineArray[Int8, size * size]
    var _scores: InlineArray[Scores, size * size] 
    var _score: Score

    fn __init__(out self):
        self._places = InlineArray[Int8, size * size](fill = 0)
        self._scores = InlineArray[Scores, size * size](uninitialized=True)
        self._score = 0

        for y in range(size):
            var v = 1 + min(win_stones - 1, y, size - 1 - y)
            for x in range(size):
                var h = 1 + min(win_stones - 1, x, size - 1 - x)
                var m = 1 + min(x, y, size - 1 - x, size - 1 - y)
                var t1 = max(0, min(win_stones, m, size - win_stones + 1 - y + x, size - win_stones + 1 - x + y))
                var t2 = max(0, min(win_stones, m, 2 * size - 1 - win_stones + 1 - y - x, x + y - win_stones + 1 + 1))
                var total = v + h + t1 + t2
                self.setscores(Place(x, y), Scores(total, total))

    fn __copyinit__(out self, existing: Self, /):
        self._places = InlineArray[Int8, size * size](uninitialized=True)
        memcpy(self._places.unsafe_ptr(), existing._places.unsafe_ptr(), size * size)

        self._scores = InlineArray[Scores, size * size](uninitialized=True)
        memcpy(self._scores.unsafe_ptr(), existing._scores.unsafe_ptr(), size * size)

        self._score = existing._score

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

    fn places(self, turn: Int) -> List[Place]:
        @parameter
        fn less_first(a: Place, b: Place, out r: Bool):
            r = self.score(a, first) < self.score(b, first)

        @parameter
        fn less_second(a: Place, b: Place, out r: Bool):
            r = self.score(a, second) < self.score(b, second)

        var places = List[Place](capacity = max_places)

        if turn == first:
            for y in range(size):
                for x in range(size):
                    if self[x, y] == self.empty:
                        heap_add[max_places, less_first](Place(x, y), places)
        else:
            for y in range(size):
                for x in range(size):
                    if self[x, y] == self.empty:
                        heap_add[max_places, less_second](Place(x, y), places)
        return places^

    fn decision(self) -> StaticString:
        for a in range(size):
            var h_stones = SIMD[DType.int64, 2](0, 0)
            var v_stones = SIMD[DType.int64, 2](0, 0)
            for b in range(win_stones - 1):
                h_stones += self._counts(self[b, a])
                v_stones += self._counts(self[a, b])
            for b in range(size - win_stones + 1):
                h_stones += self._counts(self[b + win_stones - 1, a])
                v_stones += self._counts(self[a, b + win_stones - 1])
                if h_stones[0] == win_stones or v_stones[0] == win_stones:
                    return "first-win"
                elif h_stones[1] == win_stones or v_stones[1] == win_stones:
                    return "second-win"
                h_stones -= self._counts(self[b, a])
                v_stones -= self._counts(self[a, b])

        for y in range(size - win_stones + 1):
            var stones1 = SIMD[DType.int64, 2](0, 0)
            var stones2 = SIMD[DType.int64, 2](0, 0)
            for x in range(win_stones - 1):
                stones1 += self._counts(self[x, y+x])
                stones2 += self._counts(self[size - 1 - x, x + y])
            for x in range(size - win_stones + 1 - y):
                stones1 += self._counts(self[x + win_stones - 1, x + y + win_stones - 1])
                stones2 += self._counts(self[size - x - win_stones, x + y + win_stones - 1])
                if stones1[0] == win_stones or stones2[0] == win_stones:
                    return "first-win"
                elif stones1[1] == win_stones or stones2[1] == win_stones:
                    return "second-win"
                stones1 -= self._counts(self[x, x+y])
                stones2 -= self._counts(self[size - 1 - x, x + y])

        for x in range(1, size - win_stones + 1):
            var stones1 = SIMD[DType.int64, 2](0, 0)
            var stones2 = SIMD[DType.int64, 2](0, 0)
            for y in range(win_stones - 1):
                stones1 += self._counts(self[x + y, y])
                stones2 += self._counts(self[size - 1 - x - y, y])
            for y in range(size - win_stones + 1 - x):
                stones1 += self._counts(self[x + y + win_stones - 1, y + win_stones - 1])
                stones2 += self._counts(self[size - win_stones - x - y, y + win_stones - 1])
                if stones1[0] == win_stones or stones2[0] == win_stones:
                    return "first-win"
                elif stones1[1] == win_stones or stones2[1] == win_stones:
                    return "second-win"
                stones1 -= self._counts(self[x + y, y])
                stones2 -= self._counts(self[size - 1 - x - y, y])

        for y in range(size):
            for x in range(size):
                if self[x, y] == self.empty and self.score(Place(x, y), first) > 1:
                    return "no-decision"

        return "draw"

    fn _counts(self, stones: Int8, out result: SIMD[DType.int64, 2]):
        if stones == 1:
            return SIMD[DType.int64, 2](1, 0)
        elif stones == win_stones:
            return SIMD[DType.int64, 2](0, 1)
        else:
            return SIMD[DType.int64, 2](0, 0)
    

    fn __getitem__(self, x: Int, y: Int, out result: Int8):
        result = self._places[y * size + x]

    fn __setitem__(mut self, x: Int, y: Int, value: Int8):
        self._places[y * size + x] = value

    fn score(self, place: Place, turn: Int) -> Score:
        return self._scores[Int(place.y) * size + Int(place.x)][turn]

    fn setscores(mut self, place: Place, value: Scores):
        self._scores[Int(place.y) * size + Int(place.x)] = value

    fn __str__(self, out result: String):
        result = String.write(self)

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
        str = String("\n   │")
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
                    var score = self.score(Place(x, y), table_idx)
                    if score.iswin():
                        str += " WinX "
                    elif score.isloss():
                        str += " WinO "
                    elif score.isdraw():
                        str += " Draw "
                    else:
                        str += String(Int(score.value())).rjust(5, " ") + " "
            str += "│ " + String(y + 1).rjust(2) + "\n"
        str += "───┼" + "──────" * size + "┼───"
        if not table_idx:
            str += "\n   │"
            for i in range(size):
                str += String.format("    {} ", chr(i + ord("a")))
            str += "│\n"

    fn board_value(self, scores: List[Score], out value: Score):
        value = 0.0
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

    fn _calc_value(self, stones: Int8, scores: List[Score], out value: Score):
        var black = stones % win_stones
        var white = stones // win_stones
        if white == 0:
            return scores[black]
        elif black == 0:
            return -scores[white]
        return 0


fn _value_table[win_stones: Int, scores: List[Score]]() -> InlineArray[InlineArray[Scores, win_stones * win_stones + 1], 2]:
    alias result_size = win_stones * win_stones + 1

    var s = scores
    s.append(Score.win())
    v2 = List[Scores](Scores(1, -1))
    for i in range(win_stones - 1):
        v2.append(Scores(s[i + 2].value() - s[i + 1].value(), -s[i + 1].value()))

    var result = InlineArray[InlineArray[Scores, result_size], 2](InlineArray[Scores, result_size](0))

    for i in range(win_stones - 1):
        result[0][i * win_stones] = Scores(v2[i][1], -v2[i][0])
        result[0][i] = Scores(v2[i + 1][0] - v2[i][0], v2[i][1] - v2[i + 1][1])
        result[1][i] = Scores(-v2[i][0], v2[i][1])
        result[1][i * win_stones] = Scores(v2[i][1] - v2[i + 1][1], v2[i + 1][0] - v2[i][0])
    return result
