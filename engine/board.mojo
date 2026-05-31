@fieldwise_init
struct Stone(ImplicitlyCopyable, Writable):
    var value: Int8

    comptime none = Stone(0)
    comptime black = Stone(1)
    comptime white = Stone(2)


@fieldwise_init
struct SegmentIndices(ImplicitlyCopyable):
    var len: Int
    var first_index: Int


struct Board[size: Int, win_stones: Int](Defaultable, Writable):
    comptime Stones = SIMD[DType.int8, 2]
    comptime SegmentIndicesAggregate = InlineArray[SegmentIndices, 4]
    comptime Indices = InlineArray[Self.SegmentIndicesAggregate, Self.size * Self.size]
    comptime Segments = InlineArray[Self.Stones, Self._calc_n_segments()]
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
        var result = Self.Indices(fill=Self.SegmentIndicesAggregate(fill={0, -1}))
        var offset = 0
        for y in range(Self.size):
            for x in range(Self.size - Self.win_stones + 1):
                for n in range(Self.win_stones):
                    var idx = y * Self.size + x + n
                    var len = result[idx][0].len
                    if result[idx][0].first_index == -1:
                        result[idx][0].first_index = offset
                    result[idx][0].len = len + 1
                offset += 1

        for x in range(Self.size):
            for y in range(Self.size - Self.win_stones + 1):
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x
                    var len = result[idx][1].len
                    if result[idx][1].first_index == -1:
                        result[idx][1].first_index = offset
                    result[idx][1].len = len + 1
                offset += 1

        for a in range(Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = a + b
                var y = b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x + n
                    var len = result[idx][2].len
                    if result[idx][2].first_index == -1:
                        result[idx][2].first_index = offset
                    result[idx][2].len = len + 1
                offset += 1

        for a in range(1, Self.size - Self.win_stones + 1):
            for b in range(a, Self.size - Self.win_stones + 1):
                var x = b - a
                var y = b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x + n
                    var len = result[idx][2].len
                    if result[idx][2].first_index == -1:
                        result[idx][2].first_index = offset
                    result[idx][2].len = len + 1
                offset += 1

        for a in range(Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = Self.size - a - b - 1
                var y = b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x - n
                    var len = result[idx][3].len
                    if result[idx][3].first_index == -1:
                        result[idx][3].first_index = offset
                    result[idx][3].len = len + 1
                offset += 1

        for a in range(1, Self.size - Self.win_stones + 1):
            for b in range(Self.size - Self.win_stones + 1 - a):
                var x = Self.size - b - 1
                var y = a + b
                for n in range(Self.win_stones):
                    var idx = (y + n) * Self.size + x - n
                    var len = result[idx][3].len
                    if result[idx][3].first_index == -1:
                        result[idx][3].first_index = offset
                    result[idx][3].len = len + 1
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
        print(
            t"idx={String(i).ascii_rjust(3)} [{String(i % size).ascii_rjust(2)}:{String(i / size).ascii_rjust(2)}]",
            end="",
        )
        ref place_indices = indices[i]
        for j in range(4):
            ref segment_indices = place_indices[j]
            print(t" | {segment_indices.len} {String(segment_indices.first_index).ascii_rjust(4)}", end="")
        print()
