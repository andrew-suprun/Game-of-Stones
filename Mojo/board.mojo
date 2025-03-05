from collections.string import StringSlice

from scores import Score, Scores, loss, is_win, is_loss, is_draw
from heap import add


@value
@register_passable("trivial")
struct Place(EqualityComparableCollectionElement, Stringable, Writable):
    var x: Int8
    var y: Int8

    fn __init__(out self, x: Int, y: Int):
        self.x = x
        self.y = y

    fn __init__(out self, place: String) raises:
        self.x = ord(place[0]) - ord("a")
        self.y = Int(place[1:]) - 1

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)

    fn __str__(self) -> String:
        return String(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(chr(Int(self.x) + ord("a")), self.y + 1)


alias first = 0
alias second = 1


@value
@register_passable("trivial")
struct PlaceScores:
    var offset: Int
    var scores: Scores


@value
@register_passable("trivial")
struct ScoreMark:
    var place: Place
    var score: Score
    var history_idx: Int


struct Board[size: Int, max_stones: Int, max_places: Int](Stringable, Writable):
    alias empty = Int8(0)
    alias black = Int8(1)
    alias white = Int8(max_stones)

    var places: List[Int8]
    var scores: List[Scores]
    var score: Score
    var turn: Int
    var history: List[PlaceScores]
    var history_indices: List[ScoreMark]

    fn __init__(out self):
        self.places = List[Int8](capacity=size * size)
        self.scores = List[Scores](capacity=size * size)
        for _ in range(size * size):
            self.places.append(Self.empty)
            self.scores.append(Scores(0, 0))
        self.score = 0
        self.turn = 0
        self.history = List[PlaceScores]()
        self.history_indices = List[ScoreMark]()

        for y in range(size):
            var v = 1 + min(max_stones - 1, y, size - 1 - y)
            for x in range(size):
                var h = 1 + min(max_stones - 1, x, size - 1 - x)
                var m = 1 + min(x, y, size - 1 - x, size - 1 - y)
                var t1 = max(0, min(max_stones, m, size - max_stones + 1 - y + x, size - max_stones + 1 - x + y))
                var t2 = max(0, min(max_stones, m, 2 * size - 1 - max_stones + 1 - y - x, x + y - max_stones + 1 + 1))
                var total = v + h + t1 + t2
                self.setscores(Place(x, y), Scores(total, total))

    fn place_stone(mut self, place: Place, scores: List[Scores]):
        self.history_indices.append(ScoreMark(place, self.score, len(self.history)))

        var x = Int(place.x)
        var y = Int(place.y)

        if self.turn == first:
            self.score += self.getscores(place)[first]
        else:
            self.score -= self.getscores(place)[second]

        var x_start = max(0, x - max_stones + 1)
        var x_end = min(x + max_stones, size) - max_stones + 1
        var n = x_end - x_start
        self.update_row(y * size + x_start, 1, n, scores)

        var y_start = max(0, y - max_stones + 1)
        var y_end = min(y + max_stones, size) - max_stones + 1
        n = y_end - y_start
        self.update_row(y_start * size + x, size, n, scores)

        var m = 1 + min(x, y, size - 1 - x, size - 1 - y)

        n = min(max_stones, m, size - max_stones + 1 - y + x, size - max_stones + 1 - x + y)
        if n > 0:
            var mn = min(x, y, max_stones - 1)
            var x_start = x - mn
            var y_start = y - mn
            self.update_row(y_start * size + x_start, size + 1, n, scores)

        n = min(max_stones, m, 2 * size - max_stones - y - x, x + y - max_stones + 2)
        if n > 0:
            var mn = min(size - 1 - x, y, max_stones - 1)
            var x_start = x + mn
            var y_start = y - mn
            self.update_row(y_start * size + x_start, size - 1, n, scores)

        if self.turn == first:
            self[x, y] = Self.black
        else:
            self[x, y] = Self.white

    fn update_row(mut self, start: Int, delta: Int, n: Int, scores: List[Scores]):
        for i in range(start, start + delta * (max_stones - 1 + n), delta):
            self.history.append(PlaceScores(i, self.scores[i]))

        var offset = start
        var stones = Int8(0)

        @parameter
        for i in range(max_stones - 1):
            stones += self.places[offset + i * delta]

        for _ in range(n):
            stones += self.places[offset + delta * (max_stones - 1)]
            var scores = scores[stones]
            if scores[0] != 0 or scores[1] != 0:

                @parameter
                for j in range(max_stones):
                    self.scores[offset + j * delta] += scores
            stones -= self.places[offset]
            offset += delta

    fn remove_stone(mut self):
        var idx = self.history_indices.pop()
        self[Int(idx.place.x), Int(idx.place.y)] = self.empty
        self.score = idx.score
        for i in range(idx.history_idx, len(self.history)):
            var h_scores = self.history[i]
            self.scores[h_scores.offset] = h_scores.scores
        self.history.resize(idx.history_idx)

    fn top_places(self, mut top_places: List[Place]):
        @parameter
        fn less_first(a: Place, b: Place, out r: Bool):
            r = self.getscores(a)[0] < self.getscores(b)[0]

        @parameter
        fn less_second(a: Place, b: Place, out r: Bool):
            r = self.getscores(a)[1] < self.getscores(b)[1]

        top_places.clear()

        if self.turn == first:
            for y in range(size):
                for x in range(size):
                    if self[x, y] == self.empty:
                        add[Place, max_places, less_first](Place(x, y), top_places)
        else:
            for y in range(size):
                for x in range(size):
                    if self[x, y] == self.empty:
                        add[Place, max_places, less_second](Place(x, y), top_places)

    fn max_score[player: Int](self, out r: Score):
        r = loss
        for i in range(len(self.scores)):
            var score = self.scores[i][player]
            if r < score and self.places[i] == self.empty:
                r = score

    @always_inline
    fn __getitem__(self, x: Int, y: Int, out result: Int8):
        result = self.places[y * size + x]

    @always_inline
    fn __setitem__(mut self, x: Int, y: Int, value: Int8):
        self.places[y * size + x] = value

    @always_inline
    fn getscores(self, place: Place, out result: Scores):
        result = self.scores[Int(place.y) * size + Int(place.x)]

    @always_inline
    fn setscores(mut self, place: Place, value: Scores):
        self.scores[Int(place.y) * size + Int(place.x)] = value

    @always_inline
    fn setturn(mut self, turn: Int):
        self.turn = turn

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
            str = self.str_scores_raises(0, skip_footer=True)
            str += self.str_scores_raises(1)
        except:
            str = ""

    fn str_scores_raises(self, table_idx: Int, skip_footer: Bool = False, out str: String) raises:
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
                    var value = self.getscores(Place(x, y))[table_idx]
                    if is_win(value):
                        str += " WinX "
                    elif is_loss(value):
                        str += " WinO "
                    elif is_draw(value):
                        str += " Draw "
                    else:
                        str += String(Int(value)).rjust(5, " ") + " "
            str += "│ " + String(y + 1).rjust(2) + "\n"
        str += "───┼" + "──────" * size + "┼───"
        if not skip_footer:
            str += "\n   │"
            for i in range(size):
                str += String.format("    {} ", chr(i + ord("a")))
            str += "│\n"

    fn decision(self, out decision: String):
        var black_stones = max_stones * Self.black
        var white_stones = max_stones * Self.white

        for y in range(max_stones - 1):
            var stones = Int8(0)
            for x in range(size-max_stones+1):
                stones += self[x + max_stones - 1, y]
                if stones == black_stones:
                    return "first-win"
                elif stones == white_stones:
                    return "second-win"
                stones -= self[x, y]
            
        for x in range(max_stones - 1):
            var stones = Int8(0)
            for y in range(size-max_stones+1):
                stones += self[x, y + max_stones - 1]
                if stones == black_stones:
                    return "first-win"
                elif stones == white_stones:
                    return "second-win"
                stones -= self[x, y]

        
        for y in range(size - max_stones + 1):
            var stones = Int8(0)
            for x in range(max_stones - 1):
                stones += self[x, y+x]
            for x in range(size - max_stones + 1 - y):
                stones += self[x+max_stones + 1, x + y + max_stones + 1]
                if stones == black_stones:
                    return "first-win"
                elif stones == white_stones:
                    return "second-win"
                stones -= self[x, x+y]

        for x in range(1, size - max_stones + 1):
            var stones = Int8(0)
            for y in range(max_stones - 1):
                stones += self[x+y, y]
            for y in range(size - max_stones + 1 - x):
                stones += self[x + y + max_stones - 1, y + max_stones - 1]
                if stones == black_stones:
                    return "first-win"
                elif stones == white_stones:
                    return "second-win"
                stones -= self[x+y, y]


        for y in range(size - max_stones + 1):
            var stones = Int8(0)
            for x in range(max_stones - 1):
                stones += self[size - 1 - x, x + y]
            for x in range(size - max_stones + 1 - y):
                stones += self[size - x - max_stones, x + y + max_stones - 1]
                if stones == black_stones:
                    return "first-win"
                elif stones == white_stones:
                    return "second-win"
                stones -= self[size - 1 - x, x + y]

        for x in range(1, size - max_stones + 1):
            var stones = Int8(0)
            for y in range(max_stones - 1):
                stones += self[size - 1 - x - y, y]
            for y in range(size - max_stones + 1 - x):
                stones += self[size - max_stones - x - y, y + max_stones - 1]
                if stones == black_stones:
                    return "first-win"
                elif stones == white_stones:
                    return "second-win"
                stones -= self[size - 1 - x - y, y]

        for y in range(size):
            for x in range(size):
                if self[x, y] != 0:
                    return "no-decision"

        return "draw"


    fn debug_board_value(self, scores: List[Float32], out value: Float32):
        value = Float32(0)
        for y in range(size):
            var stones = Int8(0)
            for x in range(max_stones - 1):
                stones += self[x, y]
            for x in range(size - max_stones + 1):
                stones += self[x + max_stones - 1, y]
                value += self.debug_calc_value(stones, scores)
                stones -= self[x, y]

        for x in range(size):
            var stones = Int8(0)
            for y in range(max_stones - 1):
                stones += self[x, y]
            for y in range(size - max_stones + 1):
                stones += self[x, y + max_stones - 1]
                value += self.debug_calc_value(stones, scores)
                stones -= self[x, y]

        for y in range(size - max_stones + 1):
            var stones = Int8(0)
            for x in range(max_stones - 1):
                stones += self[x, y + x]
            for x in range(size - max_stones + 1 - y):
                stones += self[x + max_stones - 1, x + y + max_stones - 1]
                value += self.debug_calc_value(stones, scores)
                stones -= self[x, x + y]

        for x in range(1, size - max_stones + 1):
            var stones = Int8(0)
            for y in range(max_stones - 1):
                stones += self[x + y, y]
            for y in range(size - max_stones + 1 - x):
                stones += self[x + y + max_stones - 1, y + max_stones - 1]
                value += self.debug_calc_value(stones, scores)
                stones -= self[x + y, y]

        for y in range(size - max_stones + 1):
            var stones = Int8(0)
            for x in range(max_stones - 1):
                stones += self[size - 1 - x, x + y]
            for x in range(size - max_stones + 1 - y):
                stones += self[
                    size - 1 - x - max_stones + 1, x + y + max_stones - 1
                ]
                value += self.debug_calc_value(stones, scores)
                stones -= self[size - 1 - x, x + y]

        for x in range(1, size - max_stones + 1):
            var stones = Int8(0)
            for y in range(max_stones - 1):
                stones += self[size - 1 - x - y, y]
            for y in range(size - max_stones + 1 - x):
                stones += self[size - max_stones - x - y, y + max_stones - 1]
                value += self.debug_calc_value(stones, scores)
                stones -= self[size - 1 - x - y, y]

    fn debug_calc_value(self, stones: Int8, scores: List[Float32], out value: Float32):
        value = 0
        var black = stones % max_stones
        var white = stones // max_stones
        if white == 0:
            return scores[Int(black)]
        elif black == 0:
            return -scores[Int(white)]
