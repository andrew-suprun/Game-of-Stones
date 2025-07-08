from benchmark import benchmark, Unit, keep
from random import random_si64, random_float64

from score import Score

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


fn fib_int(x: Int32) -> Int32:
    if x < 2:
        return x
    return fib_int(x-1) + fib_int(x-2)

fn bench_fib_int():
    var s:Int32 = 0
    for i in range(28):
        s += fib_int(i)
    keep(s)

fn fib_float(x: Int32) -> Score:
    if x < 2:
        return Score(x)
    return fib_float(x-1) + fib_float(x-2)

fn bench_fib_float():
    var s: Score = 0
    for i in range(28):
        s += fib_float(i)
    keep(s)


@fieldwise_init
struct S(Copyable, Movable):
    var i: Int
    var j: Int32

fn list(mut l: List[S]):
    l.clear()
    for i in range(1000):
        l.append(S(i, Int32(i+1)))

fn bench_list():
    var l = List[S](capacity = 1000)
    for _ in range(1000):
        list(l)
        keep(l[-1].i)


fn type() -> List[S]:
    var result = List[S](capacity = 1000)
    for i in range(1000):
        result.append(S(i, Int32(i+1)))
    return result

fn bench_type():
    for _ in range(1000):
        var l = type()
        keep(l[-1].i)


fn tuple() -> List[(Int, Int32)]:
    var result = List[(Int, Int32)](capacity = 1000)
    for i in range(1000):
        result.append((i, Int32(i+1)))
    return result

fn bench_tuple():
    for _ in range(1000):
        var l = tuple()
        keep(l[-1][0])


fn intrand() -> Int32:
    return Int32(random_si64(-10, 10))

fn rand() -> Score:
    return Score(random_float64(-10, 10))

fn main() raises:
    print("InlineArray SIMD Int  ", benchmark.run[benchInlineArraySIMDInt]().mean(Unit.ms))
    print("InlineArray SIMD Int16", benchmark.run[benchInlineArraySIMDInt16]().mean(Unit.ms))
    print("List        SIMD Int  ", benchmark.run[benchListSIMDInt]().mean(Unit.ms))
    print("List        SIMD Int16", benchmark.run[benchListSIMDInt16]().mean(Unit.ms))
    print("InlineArray SIMD Float", benchmark.run[benchInlineArraySIMDFloat]().mean(Unit.ms))
    print("List        SIMD Float", benchmark.run[benchListSIMDFloat]().mean(Unit.ms))
    print("fib int               ", benchmark.run[bench_fib_int]().mean(Unit.ms))
    print("fib float             ", benchmark.run[bench_fib_float]().mean(Unit.ms))
    print("tuple                 ", benchmark.run[bench_tuple]().mean(Unit.ms))
    print("type                  ", benchmark.run[bench_type]().mean(Unit.ms))
    print("list                  ", benchmark.run[bench_list]().mean(Unit.ms))
