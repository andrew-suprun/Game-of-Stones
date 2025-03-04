from benchmark import benchmark, keep, Unit
from random import random_si64
from utils.numerics import neg_inf


fn benchSIMD():
    var sum = Int16(0)
    var b = SIMD[DType.int16, 512](0)
    for i in range(512):
        b[i] = Int16(random_si64(-1, 2))
    for _ in range(1000):
        j = Int(random_si64(0, 512))
        b[j] = Int16.MIN_FINITE
        sum += b.reduce_max()
    keep(sum)


fn benchList():
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
    var bSIMD = benchmark.run[benchSIMD]().mean(Unit.ns)
    var bList = benchmark.run[benchList]().mean(Unit.ns)
    print("SIMD: ", bSIMD)
    print("List: ", bList)
    print("ratio:", bList / bSIMD)
