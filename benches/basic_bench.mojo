from benchmark import benchmark, Unit, keep
from random import random_si64, random_float64

from game import Score


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


fn main() raises:
    print("\n--- basic (ms/10_000) ---")
    print("InlineArray SIMD Int  ", benchmark.run[benchInlineArraySIMDInt]().mean())
    print("List        SIMD Int  ", benchmark.run[benchListSIMDInt]().mean())
    print("InlineArray SIMD Float", benchmark.run[benchInlineArraySIMDFloat]().mean())
    print("List        SIMD Float", benchmark.run[benchListSIMDFloat]().mean())
