from benchmark import benchmark, Unit
from random import seed, shuffle

from heap import Heap


fn bench():
    seed(4)

    @parameter
    fn less(a: Int, b: Int, out r: Bool):
        r = a < b

    var heap = Heap[20, less]()
    var values = List[Int]()
    for i in range(100):
        values.append(100 - i)

    for _ in range(1000):
        heap.clear()
        for i in range(100):
            heap.add(values[i])


def main():
    print("heap bench    ", benchmark.run[bench]().mean(Unit.ns))
