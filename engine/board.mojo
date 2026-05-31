@fieldwise_init
struct Stone(ImplicitlyCopyable, Writable):
    var value: Int8

    comptime none = Stone(0)
    comptime black = Stone(1)
    comptime white = Stone(2)


struct Board[size: Int, win_stones: Int](Defaultable, Writable):
    comptime Segments = InlineArray[SIMD[DType.int8, 2], Self._calc_n_segments()]
    comptime Indices = InlineArray[InlineArray[Int, Self.win_stones * 4 + 1], Self.size * Self.size]
    comptime Places = InlineArray[Stone, Self.size * Self.size]

    comptime indices = Self._calc_indices()

    var _places: Self.Places
    var _segments: Self.Segments

    def __init__(out self):
        self._places = Self.Places(fill=Stone.none)
        self._segments = Self.Segments(fill={0, 0})

    @staticmethod
    def _calc_n_segments() -> Int:
        return (
            Self.size * (Self.size - Self.win_stones + 1) * 2
            + (Self.size - Self.win_stones + 2) * (Self.size - Self.win_stones + 1)
            + (Self.size - Self.win_stones + 1) * (Self.size - Self.win_stones)
        )

    @staticmethod
    def _calc_indices() -> Self.Indices:
        var result = Self.Indices(fill=InlineArray[Int, Self.win_stones * 4 + 1](fill=0))
        var offset = 0
        for y in range(Self.size):
            for x in range(Self.size - Self.win_stones + 1):
                for n in range(Self.win_stones):
                    var idx = y * Self.size + x + n
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        for x in range(Self.size):
            for y in range(Self.size - Self.win_stones + 1):
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        for a in range(Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = a + b
                var y = b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x + n
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        for a in range(1, Self.size - Self.win_stones + 1):
            for b in range(a, Self.size - Self.win_stones + 1):
                var x = b - a
                var y = b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x + n
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        for a in range(Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = Self.size - a - b - 1
                var y = b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x - n
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        for a in range(1, Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = Self.size - b - 1
                var y = a + b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x - n
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        return result


comptime size = 19
comptime win_stones = 6
comptime B = Board[size, win_stones]


def main_x():
    print(t" segments: {B._calc_n_segments()}")
    var indices = B._calc_indices()
    for i in range(B.size * B.size):
        if i % size == 0:
            print()
        var len = indices[i][0]
        if len > 0:
            print(
                t"idx={String(i).ascii_rjust(3)} [{String(i % size).ascii_rjust(2)}:{String(i / size).ascii_rjust(2)}] |",
                end="",
            )
            for j in range(1, indices[i][0] + 1):
                print(t" {String(indices[i][j]).ascii_rjust(3)}", end="")
            print()
