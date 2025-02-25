from collections import InlineArray
from benchmark import benchmark, Unit, keep
from random import seed, random_si64, random_float64


fn benchInlineArraySIMDFloat():
    var a = InlineArray[SIMD[DType.float16, 2], 1100](0)
    for i in range(1100):
        a[i] = SIMD[DType.float16, 2](
            Float16(random_float64(0, 10)), Float16(random_float64(0, 10))
        )
    var s: SIMD[DType.float16, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchInlineArraySIMDInt():
    var a = InlineArray[SIMD[DType.int16, 2], 1100](0)
    for i in range(1100):
        a[i] = SIMD[DType.int16, 2](
            Int16(random_si64(0, 10)), Int16(random_float64(0, 10))
        )
    var s: SIMD[DType.int16, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchInlineArrayTupleFloat():
    var a = InlineArray[(Float16, Float16), 1100]((Float16(0), Float16(0)))
    for i in range(1100):
        a[i] = Float16(random_float64(0, 10)), Float16(random_float64(0, 10))
    var s = (Float16(0), Float16(0))
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s[0] += a[j][0]
            s[1] += a[j][1]
    keep(s[0])
    keep(s[1])


fn benchInlineArrayTupleInt():
    var a = InlineArray[(Int16, Int16), 1100]((Int16(0), Int16(0)))
    for i in range(1100):
        a[i] = (Int16(random_si64(0, 10)), Int16(random_float64(0, 10)))
    var s = (Int16(0), Int16(0))
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s[0] += a[j][0]
            s[1] += a[j][1]
    keep(s[0])
    keep(s[1])


fn benchListSIMDFloat():
    var a = InlineArray[SIMD[DType.float16, 2], 1100](0)
    for i in range(1100):
        a[i] = SIMD[DType.float16, 2](
            Float16(random_float64(0, 10)), Float16(random_float64(0, 10))
        )
    var s: SIMD[DType.float16, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchListSIMDInt():
    var a = List[SIMD[DType.int16, 2]](0)
    for i in range(1100):
        a[i] = SIMD[DType.int16, 2](
            Int16(random_si64(0, 10)), Int16(random_float64(0, 10))
        )
    var s: SIMD[DType.int16, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchListTupleFloat():
    var a = List[(Float16, Float16), 1100]((Float16(0), Float16(0)))
    for i in range(1100):
        a[i] = Float16(random_float64(0, 10)), Float16(random_float64(0, 10))
    var s = (Float16(0), Float16(0))
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s[0] += a[j][0]
            s[1] += a[j][1]
    keep(s[0])
    keep(s[1])


fn benchListTupleInt():
    var a = List[(Int16, Int16), 1100]((Int16(0), Int16(0)))
    for i in range(1100):
        a[i] = (Int16(random_si64(0, 10)), Int16(random_float64(0, 10)))
    var s = (Int16(0), Int16(0))
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
