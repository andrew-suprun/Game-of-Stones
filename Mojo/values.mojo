from utils.numerics import inf
from collections import InlineArray

alias Pair = SIMD[DType.float16, 2]


fn table1[
    size: Int, //, values: InlineArray[Float16, size]
](out result: InlineArray[InlineArray[Float16, size], 2]):
    result = InlineArray[InlineArray[Float16, size], 2](
        InlineArray[Float16, size](unsafe_uninitialized=True),
        InlineArray[Float16, size](unsafe_uninitialized=True),
    )
    for i in range(size):
        result[0][i] = values[i]
        result[1][i] = -values[i]


fn table2[
    size: Int, //, values: InlineArray[Float16, size]
](out result: InlineArray[InlineArray[Pair, size], 2]):
    result = InlineArray[InlineArray[Pair, size], 2](
        InlineArray[Pair, size](unsafe_uninitialized=True),
        InlineArray[Pair, size](unsafe_uninitialized=True),
    )
    for i in range(size - 1):
        result[0][i] = Pair(values[i + 1] - values[i], -values[i])
        result[1][i] = Pair(values[i], values[i] - values[i + 1])

    result[0][0] = Pair(1, -1)
    result[1][0] = Pair(1, -1)
    result[0][size - 1] = 0
    result[1][size - 1] = 0


fn table3[
    size: Int, //, values: InlineArray[Pair, size]
](out result: InlineArray[InlineArray[Pair, size], 4]):
    result = InlineArray[InlineArray[Pair, size], 4](
        InlineArray[Pair, size](unsafe_uninitialized=True),
        InlineArray[Pair, size](unsafe_uninitialized=True),
        InlineArray[Pair, size](unsafe_uninitialized=True),
        InlineArray[Pair, size](unsafe_uninitialized=True),
    )
    for i in range(size - 2):
        result[0][i] = values[i + 1] - values[i]
        result[1][i] = Pair(-values[i][1], -values[i][0])
        result[2][i] = Pair(values[i][1], values[i][0])
        result[3][i] = Pair(
            values[i][1] - values[i + 1][1], values[i][0] - values[i + 1][0]
        )

    result[1][0] = result[0][0]
    result[2][0] = result[3][0]
    for i in range(4):
        for j in range(size - 2, size - 1):
            result[i][j] = 0
