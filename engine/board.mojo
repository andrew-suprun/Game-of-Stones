from std.memory import memcpy
from std.utils.numerics import isinf, isnan, isfinite, nan

from .config import board_size
from .heap import heap_add

comptime players = 2
comptime directions = 4

comptime Value = Float32
comptime PlayerValues = SIMD[Value.dtype, players]
comptime DirectionValues = InlineArray[PlayerValues, directions]
comptime PlaceValues = InlineArray[DirectionValues, board_size**2]

comptime first = 0
comptime second = 1


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
struct PlaceValue(TrivialRegisterPassable, Writable):
    var place: Place
    var value: Value

    def write_to[W: Writer](self, mut writer: W):
        writer.write(t"{self.place} {self.value}")


def lt(a: PlaceValue, b: PlaceValue) -> Bool:
    return a.value < b.value


struct Board[win_stones: Int](Copyable, Writable):
    comptime empty = 0
    comptime black = 1
    comptime white = Self.win_stones
    comptime value_table = _calc_value_table[Self.win_stones]()

    var _places: InlineArray[Int8, board_size**2]
    var _values: PlaceValues
    var value: Value

    def __init__(out self):
        self._places = InlineArray[Int8, board_size**2](fill=Self.empty)
        self._values = PlaceValues(uninitialized=True)
        self.value = 0

        for y in range(board_size):
            for x in range(board_size):
                var h = 1 + min(Self.win_stones - 1, x, board_size - 1 - x, board_size - Self.win_stones)
                self._values[y * board_size + x][0] = Value(h)

                var v = 1 + min(Self.win_stones - 1, y, board_size - 1 - y, board_size - Self.win_stones)
                self._values[y * board_size + x][1] = Value(v)

                var m = 1 + min(x, y, board_size - 1 - x, board_size - 1 - y, board_size - Self.win_stones)
                var se = max(
                    0,
                    min(
                        Self.win_stones,
                        m,
                        board_size - Self.win_stones + 1 - y + x,
                        board_size - Self.win_stones + 1 - x + y,
                    ),
                )
                self._values[y * board_size + x][2] = Value(se)

                var sw = max(
                    0,
                    min(
                        Self.win_stones,
                        m,
                        2 * board_size - 1 - Self.win_stones + 1 - y - x,
                        x + y - Self.win_stones + 1 + 1,
                    ),
                )
                self._values[y * board_size + x][3] = Value(sw)

    def place_stone(mut self, place: Place, turn: Int):
        ref value_table = materialize[self.value_table]()
        ref values = value_table[turn]

        var x = Int(place.x)
        var y = Int(place.y)

        # TODO
        # if turn == first:
        #     self.value += self.get_value(place, first)
        # else:
        #     self.value -= self.get_value(place, second)

        var x_start = max(0, x - Self.win_stones + 1)
        var x_end = min(x + Self.win_stones, board_size) - Self.win_stones + 1
        var n = x_end - x_start
        self._update_row(y * board_size + x_start, 1, 0, n, values)

        var y_start = max(0, y - Self.win_stones + 1)
        var y_end = min(y + Self.win_stones, board_size) - Self.win_stones + 1
        n = y_end - y_start
        self._update_row(y_start * board_size + x, board_size, 1, n, values)

        var m = 1 + min(x, y, board_size - 1 - x, board_size - 1 - y)

        var upper_bound = board_size - Self.win_stones + 1
        n = min(Self.win_stones, m, upper_bound - y + x, upper_bound - x + y)
        if n > 0:
            var mn = min(x, y, Self.win_stones - 1)
            var x_start = x - mn
            var y_start = y - mn
            self._update_row(y_start * board_size + x_start, board_size + 1, 2, n, values)

        n = min(Self.win_stones, m, 2 * board_size - Self.win_stones - y - x, x + y - Self.win_stones + 2)
        if n > 0:
            var mn = min(board_size - 1 - x, y, Self.win_stones - 1)
            var x_start = x + mn
            var y_start = y - mn
            self._update_row(y_start * board_size + x_start, board_size - 1, 3, n, values)

        if turn == first:
            self[x, y] = Self.black
        else:
            self[x, y] = Self.white

        comptime for i in range(4):
            self._values[y * board_size + x][i] = 0

    def _update_row(mut self, start: Int, delta: Int, d: Int, n: Int, values: InlineArray[PlayerValues, Self.win_stones**2 + 1]):
        var offset = start
        var stones = Int8(0)

        comptime for i in range(Self.win_stones - 1):
            stones += self._places[offset + i * delta]

        for _ in range(n):
            stones += self._places[offset + delta * (Self.win_stones - 1)]
            var values = values[stones]
            if values[0] != 0 or values[1] != 0:
                comptime for j in range(Self.win_stones):
                    self._values[offset + j * delta][d] += values
            stones -= self._places[offset]
            offset += delta

    def places(self, turn: Int, mut places: List[PlaceValue]):
        for y in range(board_size):
            for x in range(board_size):
                if self[x, y] == self.empty:
                    var place = Place(x, y)
                    var value = self.get_value(place, 0, turn)  # TODO
                    heap_add[lt]({place, value}, places)

    def __getitem__(self, x: Int, y: Int) -> Int:
        return Int(self._places[y * board_size + x])

    def __setitem__(mut self, x: Int, y: Int, value: Int):
        self._places[y * board_size + x] = Int8(value)

    def get_value(self, place: Place, dir: Int, turn: Int) -> Value:
        return Value(self._values[Int(place.y) * board_size + Int(place.x)][dir][turn])

    def write_to[W: Writer](self, mut writer: W):
        try:
            self.write(writer)
        except:
            pass

    def write[W: Writer](self, mut writer: W) raises:
        writer.write("\n  ")

        for i in range(board_size):
            writer.write(t" {chr(i + ord('a'))}")
        writer.write("\n")

        for y in range(board_size):
            writer.write(String(y + 1).ascii_rjust(2))
            for x in range(board_size):
                var stone = self[x, y]
                if stone == Self.black:
                    writer.write(" X") if x == 0 else writer.write("─X")
                elif stone == Self.white:
                    writer.write(" O") if x == 0 else writer.write("─O")
                elif stone == Self.empty:
                    if y == 0:
                        if x == 0:
                            writer.write(" ┌")
                        elif x == board_size - 1:
                            writer.write("─┐")
                        else:
                            writer.write("─┬")
                    elif y == board_size - 1:
                        if x == 0:
                            writer.write(" └")
                        elif x == board_size - 1:
                            writer.write("─┘")
                        else:
                            writer.write("─┴")
                    else:
                        if x == 0:
                            writer.write(" ├")
                        elif x == board_size - 1:
                            writer.write("─┤")
                        else:
                            writer.write("─┼")
                else:
                    assert False
            writer.write(String(y + 1).ascii_rjust(3), "\n")

        writer.write("  ")

        for i in range(board_size):
            writer.write(t" {chr(i + ord('a'))}")
        writer.write("\n")

    def write_repr_to[W: Writer](self, mut writer: W):
        self.write_to(writer)
        self.write_repr_to(writer, "Black (H)", 0, 0)
        self.write_repr_to(writer, "White (H)", 0, 1)
        self.write_repr_to(writer, "Black (V)", 1, 0)
        self.write_repr_to(writer, "White (V)", 1, 1)
        self.write_repr_to(writer, "Black (SE)", 2, 0)
        self.write_repr_to(writer, "White (SE)", 2, 1)
        self.write_repr_to(writer, "Black (SW)", 3, 0)
        self.write_repr_to(writer, "White (SW)", 3, 1)

    def write_repr_to[W: Writer](self, mut writer: W, header: String, dir: Int, player: Int):
        writer.write(t"\n{header}:\n   │")
        for i in range(board_size):
            writer.write(String(t"    {chr(i + ord('a'))} "))
        writer.write("│\n")
        writer.write("───┼" + "──────" * board_size + "┼───\n")
        for y in range(board_size):
            writer.write(String(y + 1).ascii_rjust(2) + " │")
            for x in range(board_size):
                var stone = self[x, y]
                if stone == Self.black:
                    writer.write("    X ")
                elif stone == Self.white:
                    writer.write("    O ")
                else:
                    var value = self.get_value(Place(x, y), dir, player)
                    writer.write(String(value).removesuffix(".0").ascii_rjust(5, " ") + " ")
            writer.write("│ " + String(y + 1).ascii_rjust(2) + "\n")
        writer.write("───┼" + "──────" * board_size + "┼───")
        writer.write("\n   │")
        for i in range(board_size):
            writer.write(String(t"    {chr(i + ord('a'))} "))
        writer.write("│\n")

    def debug_board_value(self, values: List[Value]) -> Value:
        var value = Value(0)
        for y in range(board_size):
            var stones = 0
            for x in range(Self.win_stones - 1):
                stones += self[x, y]
            for x in range(board_size - Self.win_stones + 1):
                stones += self[x + Self.win_stones - 1, y]
                value += self._calc_value(stones, values)
                stones -= self[x, y]

        for x in range(board_size):
            var stones = 0
            for y in range(Self.win_stones - 1):
                stones += self[x, y]
            for y in range(board_size - Self.win_stones + 1):
                stones += self[x, y + Self.win_stones - 1]
                value += self._calc_value(stones, values)
                stones -= self[x, y]

        for y in range(board_size - Self.win_stones + 1):
            var stones = 0
            for x in range(Self.win_stones - 1):
                stones += self[x, y + x]
            for x in range(board_size - Self.win_stones + 1 - y):
                stones += self[x + Self.win_stones - 1, x + y + Self.win_stones - 1]
                value += self._calc_value(stones, values)
                stones -= self[x, x + y]

        for x in range(1, board_size - Self.win_stones + 1):
            var stones = 0
            for y in range(Self.win_stones - 1):
                stones += self[x + y, y]
            for y in range(board_size - Self.win_stones + 1 - x):
                stones += self[x + y + Self.win_stones - 1, y + Self.win_stones - 1]
                value += self._calc_value(stones, values)
                stones -= self[x + y, y]

        for y in range(board_size - Self.win_stones + 1):
            var stones = 0
            for x in range(Self.win_stones - 1):
                stones += self[board_size - 1 - x, x + y]
            for x in range(board_size - Self.win_stones + 1 - y):
                stones += self[board_size - 1 - x - Self.win_stones + 1, x + y + Self.win_stones - 1]
                value += self._calc_value(stones, values)
                stones -= self[board_size - 1 - x, x + y]

        for x in range(1, board_size - Self.win_stones + 1):
            var stones = 0
            for y in range(Self.win_stones - 1):
                stones += self[board_size - 1 - x - y, y]
            for y in range(board_size - Self.win_stones + 1 - x):
                stones += self[board_size - Self.win_stones - x - y, y + Self.win_stones - 1]
                value += self._calc_value(stones, values)
                stones -= self[board_size - 1 - x - y, y]
        return value

    def _calc_value(self, stones: Int, values: List[Value]) -> Value:
        var black = Int(stones) % Self.win_stones
        var white = Int(stones) / Self.win_stones
        if white == 0:
            return Value(values[black])
        elif black == 0:
            return Value(-values[white])
        return 0

    # def max_value(self, player: Int) -> Value:
    #     var max_value = self._values[0][player]

    #     for i in range(board_size * board_size):
    #         max_value = max(max_value, self._values[i][player])

    #     return max_value

    def debug_print(self, place: Place, turn: Int):
        print(t"place {place} turn={turn}")
        var x = Int(place.x)
        var y = Int(place.y)
        self.debug_print_line(x, y, 0, y, 1, 0, turn=turn)
        self.debug_print_line(x, y, x, 0, 0, 1, turn=turn)
        self.debug_print_line(x, y, x - min(x, y), y - min(x, y), 1, 1, turn=turn)
        self.debug_print_line(x, y, x + min(Self.size - 1 - x, y), y - min(Self.size - 1 - x, y), -1, 1, turn=turn)

    def debug_print_line(self, var x: Int, var y: Int, delta_x: Int, delta_y: Int, turn: Int):
        # print(t"x={x} y={y}")
        print(" |", end="")
        var place_offset = Self.size * y + x
        while 0 <= xx and xx < Self.size and yy < Self.size:
            var offset = Self.size * yy + xx
            var stone = Int(self._places[offset])
            if stone == Self.black:
                print(" X", end="")
            elif stone == Self.white:
                print(" O", end="")
            else:
                print(" _", end="")
            x += delta_x
            y += delta_y
        print(" |")


def _calc_value_table[win_stones: Int]() -> InlineArray[InlineArray[PlayerValues, win_stones**2 + 1], players]:
    var v1: List[Value] = [0, 1, 11, 111, 1111, 11111, 111111]
    var v2: List[PlayerValues] = [{1, -1}]
    for i in range(win_stones - 1):
        v2.append({v1[i + 2] - v1[i + 1], -v1[i + 1]})
    var result = InlineArray[InlineArray[PlayerValues, win_stones**2 + 1], players](fill=InlineArray[PlayerValues, win_stones**2 + 1](fill=0))

    for i in range(win_stones - 1):
        result[0][i * win_stones] = {v2[i][1], -v2[i][0]}
        result[0][i] = {v2[i + 1][0] - v2[i][0], v2[i][1] - v2[i + 1][1]}
        result[1][i] = {-v2[i][0], v2[i][1]}
        result[1][i * win_stones] = {v2[i][1] - v2[i + 1][1], v2[i + 1][0] - v2[i][0]}
    return result^
