from collections import InlineArray
from utils.numerics import isnan, isinf

from values import Pair, value_table


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
        writer.write(chr(Int(self.x) + ord("a")), self.y + 1)


alias Value = SIMD[DType.float32, 2]


@always_inline
fn is_win(v: Float32) -> Bool:
    return isinf(v) and v > 0


@always_inline
fn is_loss(v: Float32) -> Bool:
    return isinf(v) and v < 0


@always_inline
fn is_draw(v: Float32) -> Bool:
    return isnan(v)


struct Board[
    size: Int,
    max_stones: Int,
](ExplicitlyCopyable, Stringable, Writable):
    alias empty = Int8(0)
    alias black = Int8(1)
    alias white = Int8(max_stones)
    alias first = 0
    alias second = 1

    var places: List[Int8]
    var values: List[Value]
    var value: Value
    var turn: Int

    fn __init__(out self):
        self.places = List[Int8](capacity=size * size)
        self.values = List[Value](capacity=size * size)
        for _ in range(size * size):
            self.places.append(Self.empty)
            self.values.append(Value(0, 0))
        self.value = 0
        self.turn = 0

        for y in range(size):
            var v = 1 + min(max_stones - 1, y, size - 1 - y)
            for x in range(size):
                var h = 1 + min(max_stones - 1, x, size - 1 - x)
                var m = 1 + min(x, y, size - 1 - x, size - 1 - y)
                var t1 = max(
                    0,
                    min(
                        max_stones,
                        m,
                        size - max_stones + 1 - y + x,
                        size - max_stones + 1 - x + y,
                    ),
                )
                var t2 = max(
                    0,
                    min(
                        max_stones,
                        m,
                        2 * size - 1 - max_stones + 1 - y - x,
                        x + y - max_stones + 1 + 1,
                    ),
                )
                var total = v + h + t1 + t2
                self.setvalue(x, y, Value(total, -total))

    fn place_stone(
        mut self,
        place: Place,
        values: List[Value],
    ):
        var x = Int(place.x)
        var y = Int(place.y)
        self.value += self.getvalue(x, y)[self.turn]

        var x_start = max(0, x - max_stones + 1)
        var x_end = min(x + max_stones, size) - max_stones + 1
        var n = x_end - x_start
        self.update_row(y * size + x_start, 1, n, values)

        var y_start = max(0, y - max_stones + 1)
        var y_end = min(y + max_stones, size) - max_stones + 1
        n = y_end - y_start
        self.update_row(y_start * size + x, size, n, values)

        var m = 1 + min(x, y, size - 1 - x, size - 1 - y)

        n = min(
            max_stones,
            m,
            size - max_stones + 1 - y + x,
            size - max_stones + 1 - x + y,
        )
        if n > 0:
            var mn = min(x, y, max_stones - 1)
            var x_start = x - mn
            var y_start = y - mn
            self.update_row(y_start * size + x_start, size + 1, n, values)

        n = min(
            max_stones, m, 2 * size - max_stones - y - x, x + y - max_stones + 2
        )
        if n > 0:
            var mn = min(size - 1 - x, y, max_stones - 1)
            var x_start = x + mn
            var y_start = y - mn
            self.update_row(y_start * size + x_start, size - 1, n, values)

        if self.turn == Self.first:
            self[x, y] = Self.black
        else:
            self[x, y] = Self.white

    fn update_row(
        mut self,
        start: Int,
        delta: Int,
        n: Int,
        values: List[Value],
    ):
        var offset = start
        var stones = Int8(0)

        @parameter
        for i in range(max_stones - 1):
            stones += self.places[offset + i * delta]

        for _ in range(n):
            stones += self.places[offset + delta * (max_stones - 1)]
            var values = values[stones]
            if values[0] != 0 or values[1] != 0:

                @parameter
                for j in range(max_stones):
                    self.values[offset + j * delta] += values
            stones -= self.places[offset]
            offset += delta

    @always_inline
    fn __getitem__(self, x: Int, y: Int, out result: Int8):
        result = self.places[y * size + x]

    @always_inline
    fn __setitem__(mut self, x: Int, y: Int, value: Int8):
        self.places[y * size + x] = value

    @always_inline
    fn getvalue(self, x: Int, y: Int, out result: Value):
        result = self.values[y * size + x]

    @always_inline
    fn setvalue(mut self, x: Int, y: Int, value: Value):
        self.values[y * size + x] = value

    fn copy(self, out other: Self):
        other = Self()
        other.places = self.places
        other.values = self.values
        other.value = self.value
        other.turn = self.turn

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

    fn str_values(self, out str: String):
        try:
            str = self.str_values_raises(0, skip_footer=True)
            str += self.str_values_raises(1)
        except:
            str = ""

    fn str_values_raises(
        self, table_idx: Int, skip_footer: Bool = False, out str: String
    ) raises:
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
                    var value = self.getvalue(x, y)[table_idx]
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

    fn debug_board_value(self, values: List[Float32], out value: Float32):
        value = Float32(0)
        for y in range(size):
            var stones = Int8(0)
            for x in range(max_stones - 1):
                stones += self[x, y]
            for x in range(size - max_stones + 1):
                stones += self[x + max_stones - 1, y]
                value += self.debug_calc_value(stones, values)
                stones -= self[x, y]

        for x in range(size):
            var stones = Int8(0)
            for y in range(max_stones - 1):
                stones += self[x, y]
            for y in range(size - max_stones + 1):
                stones += self[x, y + max_stones - 1]
                value += self.debug_calc_value(stones, values)
                stones -= self[x, y]

        for y in range(size - max_stones + 1):
            var stones = Int8(0)
            for x in range(max_stones - 1):
                stones += self[x, y + x]
            for x in range(size - max_stones + 1 - y):
                stones += self[x + max_stones - 1, x + y + max_stones - 1]
                value += self.debug_calc_value(stones, values)
                stones -= self[x, x + y]

        for x in range(1, size - max_stones + 1):
            var stones = Int8(0)
            for y in range(max_stones - 1):
                stones += self[x + y, y]
            for y in range(size - max_stones + 1 - x):
                stones += self[x + y + max_stones - 1, y + max_stones - 1]
                value += self.debug_calc_value(stones, values)
                stones -= self[x + y, y]

        for y in range(size - max_stones + 1):
            var stones = Int8(0)
            for x in range(max_stones - 1):
                stones += self[size - 1 - x, x + y]
            for x in range(size - max_stones + 1 - y):
                stones += self[
                    size - 1 - x - max_stones + 1, x + y + max_stones - 1
                ]
                value += self.debug_calc_value(stones, values)
                stones -= self[size - 1 - x, x + y]

        for x in range(1, size - max_stones + 1):
            var stones = Int8(0)
            for y in range(max_stones - 1):
                stones += self[size - 1 - x - y, y]
            for y in range(size - max_stones + 1 - x):
                stones += self[size - max_stones - x - y, y + max_stones - 1]
                value += self.debug_calc_value(stones, values)
                stones -= self[size - 1 - x - y, y]

    fn debug_calc_value(
        self, stones: Int8, values: List[Float32], out value: Float32
    ):
        value = 0
        var black = stones % max_stones
        var white = stones // max_stones
        if white == 0:
            return values[Int(black)]
        elif black == 0:
            return -values[Int(white)]
