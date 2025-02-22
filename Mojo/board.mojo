from collections import InlineArray
from utils.numerics import isnan, isinf


alias Value = SIMD[DType.float16, 2]


@always_inline
fn is_win(v: Float16) -> Bool:
    return isinf(v) and v > 0


@always_inline
fn is_loss(v: Float16) -> Bool:
    return isinf(v) and v < 0


@always_inline
fn is_draw(v: Float16) -> Bool:
    return isnan(v)


struct Board[size: Int, max_stones: Int](Stringable, Writable):
    alias empty = 0
    alias black = 1
    alias white = max_stones + 1
    var places: InlineArray[Int8, size * size]
    var values: InlineArray[Value, size * size]

    fn __init__(out self):
        self.places = InlineArray[Int8, size * size](Self.empty)
        self.values = InlineArray[Value, size * size](Value(0, 0))
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
                        size - max_stones - 1 - y + x,
                        size - max_stones - 1 - x + y,
                    ),
                )
                var t2 = max(
                    0,
                    min(
                        max_stones,
                        m,
                        2 * size - 1 - max_stones - 1 - y - x,
                        x + y - max_stones - 1 + 1,
                    ),
                )
                var total = v + h + t1 + t2
                self.setvalue(x, y, Value(total, -total))

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
