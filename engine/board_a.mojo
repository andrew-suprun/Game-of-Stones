from .config import board_size, win_stones

comptime Stone = Int8
comptime empty: Stone = 0
comptime black: Stone = 1
comptime white: Stone = 2
comptime n_places = board_size**2


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


struct BoardA(Writable):
    var _places: InlineArray[Int8, n_places]

    def __init__(out self):
        self._places = InlineArray[Int8, n_places](fill=empty)

    def place_stone(mut self, place: Place, stone: Stone):
        self._places[place.y * board_size + place.x] = stone

    def top_moves(self):
        for start in range(0, n_places, board_size):
            self.scan_line(start, 1, board_size)
        print()

        for start in range(0, board_size):
            self.scan_line(start, board_size, board_size)
        print()

        var n = win_stones
        for start in range(n_places - board_size * win_stones, 0, -board_size):
            self.scan_line(start, board_size + 1, n)
            n += 1

        n = board_size
        for start in range(0, board_size - win_stones + 1):
            self.scan_line(start, board_size + 1, n)
            n -= 1
        print()

        n = win_stones
        for start in range(win_stones - 1, board_size - 1):
            self.scan_line(start, board_size - 1, n)
            n += 1

        n = board_size
        for start in range(board_size - 1, board_size * (board_size - win_stones + 1), board_size):
            self.scan_line(start, board_size - 1, n)
            n -= 1
        print()

    def scan_line(self, start: Int, delta: Int, n: Int):
        var offset = start
        # var place_offset = Place(offset % board_size, offset // board_size)
        # print(t"start={place_offset} n={n}")

        var color = empty
        var first = 0
        var last = 0
        var last_seen = 0
        var n_stones = 0

        for _ in range(n):
            var stone = self._places[offset]
            print(" ." if stone == empty else " X" if stone == black else " O", end="")
            offset += delta

        offset = start
        for i in range(n):
            var stone = self._places[offset]
            # print(" ." if stone == empty else " X" if stone == black else " O", end="")
            offset += delta

            if stone == empty:
                continue

            if stone == color:
                last = i
                n_stones += 1
            else:
                if color != empty and n_stones > 0:
                    if i - last_seen >= win_stones:
                        var stone_color = "X" if color == black else "O"
                        print(t" | {stone_color}: ({first-last_seen}) {n_stones}/{last-first+1} ({i-last-1}) [{i - last_seen}]", end="")
                    last_seen = last + 1
                first = i
                last = i
                color = stone
                n_stones = 1
        if n_stones > 0 and n - last_seen >= win_stones:
            var stone_color = "X" if color == black else "O"
            print(t" | {stone_color}: ({first-last_seen}) {n_stones}/{last-first+1} ({n-last-1}) [{n - last_seen}]", end="")
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
                    writer.write(" X") if x == 0 else writer.write("─X")
                elif stone == white:
                    writer.write(" O") if x == 0 else writer.write("─O")
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
