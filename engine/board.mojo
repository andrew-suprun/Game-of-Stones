struct Board[size: Int, win_stones: Int](Defaultable, Writable):
    comptime Segments = InlineArray[SIMD[DType.int8, 2], Self._calc_n_segments()]
    comptime Indices = InlineArray[InlineArray[Int, Self.win_stones * 4 + 1], Self.size * Self.size]

    var segments: Self.Segments
    var indices: Self.Indices

    def __init__(out self):
        self.segments = Self.Segments(fill={0, 0})
        self.indices = Self._calc_indices()

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
        # print("---- 1")
        for y in range(Self.size):
            for x in range(Self.size - Self.win_stones + 1):
                # print(t"x={x} y={y} offset={offset}")
                for n in range(Self.win_stones):
                    var idx = y * Self.size + x + n
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        # print("---- 2")
        for x in range(Self.size):
            for y in range(Self.size - Self.win_stones + 1):
                # print(t"x={x} y={y} offset={offset}")
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        # print("---- 3")
        for a in range(Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = a + b
                var y = b
                # print(t"x={x} y={y} offset={offset}")
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x + n
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        # print("---- 4")
        for a in range(1, Self.size - Self.win_stones + 1):
            for b in range(a, Self.size - Self.win_stones + 1):
                var x = b - a
                var y = b
                # print(t"x={x} y={y} offset={offset}")
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x + n
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        # print("---- 5")
        for a in range(Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = Self.size - a - b - 1
                var y = b
                # print(t"x={x} y={y} offset={offset}")
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x - n
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        # print("---- 6")
        for a in range(1, Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = Self.size - b - 1
                var y = a + b
                # print(t"x={x} y={y} offset={offset}")
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x - n
                    # print(t"  idx={idx}")
                    var len = result[idx][0]
                    result[idx][len + 1] = offset
                    result[idx][0] = len + 1
                offset += 1

        return result


comptime size = 19
comptime win_stones = 6
comptime B = Board[size, win_stones]


def main():
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
