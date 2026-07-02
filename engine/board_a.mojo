from std.bit import pop_count

from .config import board_size, win_stones

comptime players = 2
comptime first = 0
comptime second = 1

comptime Direction = Int
comptime directions = 4
comptime E = 0
comptime S = 1
comptime SE = 2
comptime SW = 3
comptime deltas = [1, board_size, board_size + 1, board_size - 1]

comptime Stone = Int8
comptime empty: Stone = 0
comptime black: Stone = 1
comptime white: Stone = 2
comptime n_places = board_size**2

comptime Value = Int8
comptime DirectionValues = SIMD[Value.dtype, directions]
comptime PlayerValues = InlineArray[DirectionValues, players]
comptime PlaceValues = InlineArray[PlayerValues, n_places]

comptime Places = InlineArray[Stone, n_places]


@fieldwise_init
struct Place(Comparable, Copyable, Defaultable, TrivialRegisterPassable, Writable):
    var x: Int
    var y: Int

    def __init__(out self):
        self.x = -1
        self.y = -1

    @implicit
    def __init__(out self, place: String) raises:
        self.x = ord(place[byte=0]) - ord("a")
        self.y = Int(place[byte=1:]) - 1

    def __eq__(self, other: Self) -> Bool:
        return self.x == other.x and self.y == other.y

    def __lt__(self, other: Self) -> Bool:
        return self.x < other.x or self.x == other.x and self.y < other.y

    def write_to[W: Writer](self, mut writer: W):
        writer.write(chr(Int(self.x) + ord("a")), self.y + 1)


struct Board(Writable):
    var _places: Places
    var _values: PlaceValues

    def __init__(out self):
        self._places = Places(fill=empty)
        self._values = PlaceValues(fill=PlayerValues(fill=0))

    def place_stone(mut self, place: Place, stone: Stone):
        self._places[place.y * board_size + place.x] = stone

    def top_moves(mut self):
        for start in range(0, n_places, board_size):
            self.scan_line(start, 1, board_size, E)
        print()

        for start in range(0, board_size):
            self.scan_line(start, board_size, board_size, S)
        print()

        var n = win_stones
        for start in range(n_places - board_size * win_stones, 0, -board_size):
            self.scan_line(start, board_size + 1, n, SE)
            n += 1

        n = board_size
        for start in range(0, board_size - win_stones + 1):
            self.scan_line(start, board_size + 1, n, SE)
            n -= 1
        print()

        n = win_stones
        for start in range(win_stones - 1, board_size - 1):
            self.scan_line(start, board_size - 1, n, SW)
            n += 1

        n = board_size
        for start in range(board_size - 1, board_size * (board_size - win_stones + 1), board_size):
            self.scan_line(start, board_size - 1, n, SW)
            n -= 1
        print()

    def scan_line(mut self, start: Int, delta: Int, n: Int, dir: Direction):
        var offset = start
        var blacks = Int8(0)
        var whites = Int8(0)

        # var place_offset = Place(offset % board_size, offset // board_size)
        # print(t"start={place_offset} n={n}")

        for i in range(n):
            self._values[offset + i * delta][0][dir] = 0
            self._values[offset + i * delta][1][dir] = 0

        comptime for i in range(win_stones - 1):
            var stone = self._places[offset + i * delta]
            if stone == black:
                blacks += 1
            elif stone == white:
                whites += 1

        for _ in range(n - win_stones + 1):
            var stone = self._places[offset + delta * (win_stones - 1)]
            if stone == black:
                blacks += 1
            elif stone == white:
                whites += 1

            if blacks > 0 and whites == 0:
                comptime for j in range(win_stones):
                    var value = self._values[offset + j * delta][0][dir]
                    if value < blacks:
                        self._values[offset + j * delta][0][dir] = blacks
            elif blacks == 0 and whites > 0:
                comptime for j in range(win_stones):
                    var value = self._values[offset + j * delta][1][dir]
                    if value < whites:
                        self._values[offset + j * delta][1][dir] = whites

            stone = self._places[offset]
            if stone == black:
                blacks -= 1
            elif stone == white:
                whites -= 1
            offset += delta

        offset = start
        print("x:", end="")
        for _ in range(n):
            var stone = self._places[offset]
            var value = self._values[offset][0][dir]
            if stone == empty:
                if value == 0:
                    print(" .", end="")
                else:
                    print(String(value).ascii_rjust(2), end="")
            else:
                print(" x" if stone == black else " o", end="")
            offset += delta

        print()

        offset = start
        print("o:", end="")
        for _ in range(n):
            var stone = self._places[offset]
            var value = self._values[offset][1][dir]
            if stone == empty:
                if value == 0:
                    print(" .", end="")
                else:
                    print(String(value).ascii_rjust(2), end="")
            else:
                print(" x" if stone == black else " o", end="")
            offset += delta

        print()
        print()

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
                var stone = self._places[y * board_size + x]
                if stone == black:
                    writer.write(" x") if x == 0 else writer.write("─x")
                elif stone == white:
                    writer.write(" o") if x == 0 else writer.write("─o")
                elif stone == empty:
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
