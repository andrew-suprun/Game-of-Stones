from utils.numerics import inf
from collections import InlineArray
from math import sqrt

alias Pair = SIMD[DType.float16, 2]


fn value_table[
    size: Int, //, values: InlineArray[Float16, size]
](out result: InlineArray[InlineArray[Pair, size * size], 2]):
    var v2 = InlineArray[Pair, size](0)
    for i in range(size - 1):
        v2[i] = Pair(values[i + 1] - values[i], -values[i])
    v2[0] = Pair(1, -1)

    result = InlineArray[InlineArray[Pair, size * size], 2](
        InlineArray[Pair, size * size](0),
        InlineArray[Pair, size * size](0),
    )
    for i in range(size - 2):
        result[0][i * size] = Pair(-v2[i][1], -v2[i][0])
        result[0][i] = v2[i + 1] - v2[i]
        result[1][i] = Pair(v2[i][1], v2[i][0])
        result[1][i * size] = Pair(
            v2[i][1] - v2[i + 1][1], v2[i][0] - v2[i + 1][0]
        )
