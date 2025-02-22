from collections import InlineArray

alias Cell = SIMD[DType.int8, 2]
alias black: Cell = Cell(1, 0)
alias white: Cell = Cell(0, 1)
alias empty: Cell = Cell(0, 0)

alias Value = SIMD[DType.float16, 2]


struct Board[size: Int, max_stones: Int](Stringable, Writable):
    var cells: InlineArray[Cell, size * size]
    var values: InlineArray[Value, size * size]

    fn __init__(out self):
        self.cells = InlineArray[Cell, size * size](empty)
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
    fn __getitem__(self, x: Int, y: Int, out result: Cell):
        result = self.cells[y * size + x]

    @always_inline
    fn __setitem__(mut self, x: Int, y: Int, value: Cell):
        self.cells[y * size + x] = value

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
                var cell = self[x, y]
                if cell[0] == 1:
                    writer.write(" X") if x == 0 else writer.write("─X")
                elif cell[1] == 1:
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
            writer.write(String(y + 1).rjust(2), "\n")

        writer.write("  ")

        for i in range(size):
            writer.write(String.format(" {}", chr(i + ord("a"))))
        writer.write("\n")
