from utils.numerics import inf
from collections import InlineArray
from math import sqrt

alias Pair = SIMD[DType.float16, 2]


fn value_table[
    size: Int, //, values: InlineArray[Float16, size]
](out result: InlineArray[List[Pair], 2]):
    alias max_stones = size + 1
    alias result_size = max_stones * max_stones

    v2 = InlineArray[Pair, size + 2](0)
    for i in range(size - 1):
        v2[i + 1] = Pair(values[i + 1] - values[i], -values[i])
    v2[0] = Pair(1, -1)
    v2[size] = Pair(inf[DType.float16](), -values[size - 1])

    result = InlineArray[List[Pair], 2](
        List[Pair](capacity=(size + 1) * (size + 1)),
        List[Pair](capacity=(size + 1) * (size + 1)),
    )
    for i in range((size + 1) * (size + 1)):
        result[0][i] = 0
        result[1][i] = 0

    for i in range(size):
        result[0][i * max_stones] = Pair(-v2[i][1], -v2[i][0])
        result[0][i] = v2[i + 1] - v2[i]
        result[1][i] = Pair(-v2[i][0], -v2[i][1])
        result[1][i * max_stones] = Pair(
            v2[i][1] - v2[i + 1][1], v2[i][0] - v2[i + 1][0]
        )
