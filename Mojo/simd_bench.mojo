from benchmark import benchmark, keep
from random import random_si64, random_float64
from utils.numerics import neg_inf


fn benchSIMD():
    var sum = Float32(0)
    var b = SIMD[DType.float32, 512](0)
    for i in range(512):
        b[i] = Float32(random_float64(-1, 1))
    for _ in range(1000):
        j = Int(random_si64(0, 512))
        b[j] = neg_inf[DType.float32]()
        sum += b.reduce_max()
    keep(sum)


fn benchList():
    var sum = Float32(0)
    var b = List[Float32]()
    for _ in range(361):
        b.append(Float32(random_float64(-1, 1)))
    for _ in range(1000):
        j = Int(random_si64(0, 360))
        b[j] = neg_inf[DType.float32]()
        max = neg_inf[DType.float32]()
        for i in range(361):
            if max < b[i]:
                max = b[i]
        sum += max
    keep(sum)


def main():
    var bSIMD = benchmark.run[benchSIMD]().mean()
    var bList = benchmark.run[benchList]().mean()
    print("SIMD: ", bSIMD)
    print("List: ", bList)
    print("ratio:", bList / bSIMD)
