from collections import InlineArray
from benchmark import benchmark, Unit, keep
from random import seed, random_si64, random_float64

from scores import Score

alias a = get_a()


fn get_a(out a: List[(Score, Score)]):
    a = List[(Score, Score)]()
    for i in range(1100):
        a.append((Score(1), Score(2)))


fn b_parameter[a: List[(Score, Score)]]():
    var s: (Score, Score) = (Score(0), Score(0))
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s[0] += a[j][0]
            s[1] += a[j][1]
    keep(s[0])
    keep(s[1])


fn benchParameter():
    b_parameter[a]()


fn b_argument(a: List[(Score, Score)]):
    var s: (Score, Score) = (Score(0), Score(0))
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s[0] += a[j][0]
            s[1] += a[j][1]
    keep(s[0])
    keep(s[1])


fn benchAgrument():
    b_argument(a)


fn benchInlineArraySIMDFloat():
    var a = InlineArray[SIMD[DType.float32, 2], 1100](0)
    for i in range(1100):
        a[i] = SIMD[DType.float32, 2](
            Score(random_float64(0, 10)), Score(random_float64(0, 10))
        )
    var s: SIMD[DType.float32, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchInlineArraySIMDInt():
    var a = InlineArray[SIMD[DType.float32, 2], 1100](0)
    for i in range(1100):
        a[i] = SIMD[DType.float32, 2](
            Score(random_si64(0, 10)), Score(random_float64(0, 10))
        )
    var s: SIMD[DType.float32, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchInlineArrayTupleFloat():
    var a = InlineArray[(Score, Score), 1100]((Score(0), Score(0)))
    for i in range(1100):
        a[i] = Score(random_float64(0, 10)), Score(random_float64(0, 10))
    var s = (Score(0), Score(0))
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s[0] += a[j][0]
            s[1] += a[j][1]
    keep(s[0])
    keep(s[1])


fn benchInlineArrayTupleInt():
    var a = InlineArray[(Score, Score), 1100]((Score(0), Score(0)))
    for i in range(1100):
        a[i] = (Score(random_si64(0, 10)), Score(random_float64(0, 10)))
    var s = (Score(0), Score(0))
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s[0] += a[j][0]
            s[1] += a[j][1]
    keep(s[0])
    keep(s[1])


fn benchListSIMDFloat():
    var a = InlineArray[SIMD[DType.float32, 2], 1100](0)
    for i in range(1100):
        a[i] = SIMD[DType.float32, 2](
            Score(random_float64(0, 10)), Score(random_float64(0, 10))
        )
    var s: SIMD[DType.float32, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchListSIMDInt():
    var a = List[SIMD[DType.float32, 2]](0)
    for _ in range(1100):
        a.append(
            SIMD[DType.float32, 2](
                Score(random_si64(0, 10)), Score(random_float64(0, 10))
            )
        )
    var s: SIMD[DType.float32, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchListTupleFloat():
    var a = List[(Score, Score), 1100]((Score(0), Score(0)))
    for _ in range(1100):
        a.append((Score(random_float64(0, 10)), Score(random_float64(0, 10))))
    var s = (Score(0), Score(0))
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s[0] += a[j][0]
            s[1] += a[j][1]
    keep(s[0])
    keep(s[1])


fn benchListTupleInt():
    var a = List[(Score, Score), 1100]((Score(0), Score(0)))
    for _ in range(1100):
        a.append((Score(random_si64(0, 10)), Score(random_float64(0, 10))))
    var s = (Score(0), Score(0))
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s[0] += a[j][0]
            s[1] += a[j][1]
    keep(s[0])
    keep(s[1])


def main():
    seed(1)

    print(
        "benchParameter            ",
        benchmark.run[benchParameter]().mean(),
    )
    print(
        "benchAgrument             ",
        benchmark.run[benchAgrument]().mean(),
    )
    print(
        "benchInlineArraySIMDFloat ",
        benchmark.run[benchInlineArraySIMDFloat]().mean(),
    )
    print(
        "benchInlineArraySIMDInt   ",
        benchmark.run[benchInlineArraySIMDInt]().mean(),
    )
    print(
        "benchInlineArrayTupleFloat",
        benchmark.run[benchInlineArrayTupleFloat]().mean(),
    )
    print(
        "benchInlineArrayTupleInt  ",
        benchmark.run[benchInlineArrayTupleInt]().mean(),
    )
    print(
        "benchListSIMDFloat        ", benchmark.run[benchListSIMDFloat]().mean()
    )
    print(
        "benchListSIMDInt          ", benchmark.run[benchListSIMDInt]().mean()
    )
    print(
        "benchListTupleFloat       ",
        benchmark.run[benchListTupleFloat]().mean(),
    )
    print(
        "benchListTupleInt         ", benchmark.run[benchListTupleInt]().mean()
    )
