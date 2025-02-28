from scores import Scores


fn value_table[
    max_stones: Int, values: List[Float32]
](out result: (List[Scores], List[Scores])):
    alias result_size = max_stones * max_stones

    v2 = List[Scores](Scores(1, -1))
    for i in range(max_stones - 1):
        v2.append(Scores(values[i + 2] - values[i + 1], -values[i + 1]))

    result = (
        List[Scores](capacity=max_stones * max_stones),
        List[Scores](capacity=max_stones * max_stones),
    )
    for _ in range(max_stones * max_stones):
        result[0].append(0)
        result[1].append(0)

    for i in range(max_stones - 1):
        result[0][i * max_stones] = Scores(v2[i][1], v2[i][0])
        result[0][i] = v2[i + 1] - v2[i]
        result[1][i] = v2[i]
        result[1][i * max_stones] = Scores(
            v2[i + 1][1] - v2[i][1], v2[i + 1][0] - v2[i][0]
        )
