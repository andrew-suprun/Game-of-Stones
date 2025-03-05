from benchmark import benchmark, keep, Unit
from random import random_si64
from utils.numerics import neg_inf


fn bench_simd_reduce():
    var sum = Int16(0)
    var b = SIMD[DType.int16, 512](0)
    for i in range(512):
        b[i] = Int16(random_si64(-1, 2))
    for _ in range(1000):
        j = Int(random_si64(0, 512))
        b[j] = Int16.MIN_FINITE
        sum += b.reduce_max()
    keep(sum)


fn bench_simd_loop():
    var sum = Int16(0)
    var b = SIMD[DType.int16, 512](0)
    for i in range(512):
        b[i] = Int16(random_si64(-1, 2))
    for _ in range(1000):
        j = Int(random_si64(0, 512))
        b[j] = Int16.MIN_FINITE
        max = Int16.MIN_FINITE
        for i in range(361):
            if b[i] > 0 and max < b[i]:
                max = b[i]
        sum += max
    keep(sum)


fn bench_list():
    var sum = Int16(0)
    var b = List[Int16]()
    for _ in range(361):
        b.append(Int16(random_si64(-1, 2)))
    for _ in range(1000):
        j = Int(random_si64(0, 360))
        b[j] = Int16.MIN_FINITE
        max = Int16.MIN_FINITE
        for i in range(361):
            if b[i] > 0 and max < b[i]:
                max = b[i]
        sum += max
    keep(sum)


def main():
    var simd_reduce = benchmark.run[bench_simd_reduce]().mean(Unit.ns)
    print("SIMD reduce: ", simd_reduce)
    var simd_loop = benchmark.run[bench_simd_loop]().mean(Unit.ns)
    print("SIMD loop:   ", simd_loop)
    var list = benchmark.run[bench_list]().mean(Unit.ns)
    print("List:        ", list)
