from collections import InlineArray

from scores import Score, Scores

fn value_table[max_stones: Int, scores: List[Score]](out result: InlineArray[InlineArray[Scores, max_stones * max_stones], 2]):
    alias result_size = max_stones * max_stones

    v2 = List[Scores](Scores(1, -1))
    for i in range(max_stones - 1):
        v2.append(Scores(scores[i + 2] - scores[i + 1], -scores[i + 1]))

    result = InlineArray[InlineArray[Scores, result_size], 2](
        InlineArray[Scores, result_size](uninitialized=True),
        InlineArray[Scores, result_size](uninitialized=True),
    )
    for i in range(result_size):
        result[0][i] = 0
        result[1][i] = 0

    for i in range(max_stones - 1):
        result[0][i * max_stones] = Scores(v2[i][1], -v2[i][0])
        result[0][i] = Scores(v2[i + 1][0] - v2[i][0], v2[i][1] - v2[i + 1][1])
        result[1][i] = Scores(-v2[i][0], v2[i][1])
        result[1][i * max_stones] = Scores(v2[i][1] - v2[i + 1][1], v2[i + 1][0] - v2[i][0])
