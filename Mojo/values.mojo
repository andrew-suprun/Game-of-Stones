from scores import Pair


fn value_table[
    max_stones: Int, values: List[Float32]
](out result: (List[Pair], List[Pair])):
    alias result_size = max_stones * max_stones

    v2 = List[Pair](Pair(1, -1))
    for i in range(max_stones - 1):
        v2.append(Pair(values[i + 2] - values[i + 1], -values[i + 1]))

    result = (
        List[Pair](capacity=max_stones * max_stones),
        List[Pair](capacity=max_stones * max_stones),
    )
    for _ in range(max_stones * max_stones):
        result[0].append(0)
        result[1].append(0)

    for i in range(max_stones - 1):
        result[0][i * max_stones] = Pair(v2[i][1], v2[i][0])
        result[0][i] = v2[i + 1] - v2[i]
        result[1][i] = Pair(-v2[i][0], -v2[i][1])
        result[1][i * max_stones] = Pair(
            v2[i][1] - v2[i + 1][1], v2[i][0] - v2[i + 1][0]
        )
