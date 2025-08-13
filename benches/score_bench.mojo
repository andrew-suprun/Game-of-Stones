from benchmark import benchmark, Unit, keep
from random import random_si64, random_float64

alias Scores = SIMD[DType.float32, 2]


fn benchScores1():
    var a = List[Scores](capacity=361)
    for i in range(361):
        a[i] = Scores(rand(), rand())
    var max_score: Scores = 0
    for _ in range(10_000):
        for j in range(361):
            max_score = max(max_score, a[j])
    keep(max_score)


fn benchScores2():
    var a = List[Scores](capacity=361)
    for i in range(361):
        a[i] = Scores(rand(), rand())
    var max_score: Float32 = 0
    for _ in range(10_000):
        for j in range(361):
            max_score = max(max_score, a[j][0])
    keep(max_score)


fn rand() -> Float32:
    return Float32(random_float64(-10, 10))


fn main() raises:
    print("Scores.1", benchmark.run[benchScores1]().mean(Unit.ms))
    print("Scores.2", benchmark.run[benchScores2]().mean(Unit.ms))
