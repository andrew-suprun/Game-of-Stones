from benchmark import benchmark, Unit, keep
from random import random_si64, random_float64

fn benchInlineArraySIMDInt():
    var a = InlineArray[SIMD[DType.int32, 2], 1100](uninitialized = True)
    for i in range(1100):
        a[i] = SIMD[DType.int32, 2](
            intrand(), intrand()
        )
    var s: SIMD[DType.int32, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchInlineArraySIMDInt16():
    var a = InlineArray[SIMD[DType.int16, 2], 1100](uninitialized = True)
    for i in range(1100):
        a[i] = SIMD[DType.int16, 2](
            Int16(intrand()), Int16(intrand())
        )
    var s: SIMD[DType.int16, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchListSIMDInt():
    var a = List[SIMD[DType.int32, 2]](capacity = 1100)
    for _ in range(1100):
        a.append(
            SIMD[DType.int32, 2](
                intrand(), intrand()
            )
        )
    var s: SIMD[DType.int32, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchListSIMDInt16():
    var a = List[SIMD[DType.int16, 2]](capacity = 1100)
    for _ in range(1100):
        a.append(
            SIMD[DType.int16, 2](
            Int16(intrand()), Int16(intrand())
            )
        )
    var s: SIMD[DType.int16, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchInlineArraySIMDFloat():
    var a = InlineArray[SIMD[DType.float32, 2], 1100](uninitialized = True)
    for i in range(1100):
        a[i] = SIMD[DType.float32, 2](
            rand(), rand()
        )
    var s: SIMD[DType.float32, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn benchListSIMDFloat():
    var a = List[SIMD[DType.float32, 2]](capacity = 1100)
    for _ in range(1100):
        a.append(
            SIMD[DType.float32, 2](
                rand(), rand()
            )
        )
    var s: SIMD[DType.float32, 2] = 0
    for _ in range(10_000):
        var x = random_si64(0, 100)
        for j in range(x, x + 1000):
            s += a[j]
    keep(s)


fn intrand() -> Int32:
    return Int32(random_si64(-10, 10))

fn rand() -> Float32:
    return Float32(random_float64(-10, 10))

fn main() raises:
    print("InlineArray SIMD Int  ", benchmark.run[benchInlineArraySIMDInt]().mean(Unit.ms))
    print("InlineArray SIMD Int16", benchmark.run[benchInlineArraySIMDInt16]().mean(Unit.ms))
    print("List        SIMD Int  ", benchmark.run[benchListSIMDInt]().mean(Unit.ms))
    print("List        SIMD Int16", benchmark.run[benchListSIMDInt16]().mean(Unit.ms))
    print("InlineArray SIMD Float", benchmark.run[benchInlineArraySIMDFloat]().mean(Unit.ms))
    print("List        SIMD Float", benchmark.run[benchListSIMDFloat]().mean(Unit.ms))
