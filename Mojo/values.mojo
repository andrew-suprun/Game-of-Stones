from utils.numerics import inf
from collections import InlineArray
from math import sqrt

alias Pair = SIMD[DType.float16, 2]


fn table1[
    size: Int, //, values: InlineArray[Float16, size]
](out result: InlineArray[Float16, size * size]):
    result = InlineArray[Float16, size * size](0)
    for i in range(size):
        result[i] = values[i]
        result[i * size] = -values[i]


fn table2[
    size: Int, //, values: InlineArray[Float16, size]
](out result: InlineArray[Pair, size * size]):
    result = InlineArray[Pair, size * size](0)
    for i in range(size - 1):
        result[i] = Pair(values[i + 1] - values[i], -values[i])
        result[i * size] = Pair(values[i], values[i] - values[i + 1])

    result[0] = Pair(1, -1)


fn table3[
    size: Int, //, values: InlineArray[Pair, size], max_stones: Int
](out result: InlineArray[InlineArray[Pair, size], 2]):
    result = InlineArray[InlineArray[Pair, size], 2](
        InlineArray[Pair, size](0),
        InlineArray[Pair, size](0),
    )
    for i in range(max_stones - 1):
        result[0][i * (max_stones + 1)] = Pair(-values[i][1], -values[i][0])
        result[0][i] = values[i + 1] - values[i]
        result[1][i] = Pair(values[i][1], values[i][0])
        result[1][i * (max_stones + 1)] = Pair(
            values[i][1] - values[i + 1][1], values[i][0] - values[i + 1][0]
        )
