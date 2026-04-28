from std.benchmark import benchmark, Unit, keep, black_box
from std.random import random_float64

from score_float import Score


def bench_score():
    var scores = InlineArray[Score, 1000](fill=Score())
    for ref score in scores:
        score.value = Float32(random_float64(0, 1000))
    for _ in range(1000):
        var scores = black_box(scores)
        var max_score = Score()
        for score in scores:
            if max_score < score:
                max_score = score
        keep(max_score)


def bench_float():
    var scores = InlineArray[Float32, 1000](fill=0)
    for ref score in scores:
        score = Float32(random_float64(0, 1000))
    for _ in range(1000):
        var scores = black_box(scores)
        var max_score = Float32()
        for score in scores:
            if max_score < score:
                max_score = score
        keep(max_score)


def main() raises:
    print("--- score ---")
    print("score  ", benchmark.run[func2=bench_score](0, 1, 3, 6).mean(Unit.ms))
    print("float  ", benchmark.run[func2=bench_float](0, 1, 3, 6).mean(Unit.ms))
