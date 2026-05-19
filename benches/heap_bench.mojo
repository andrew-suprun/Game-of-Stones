from std.benchmark import benchmark, Unit, keep

from heap import heap_add


def lt(a: Int, b: Int) -> Bool:
    return a < b


def bench():
    var heap = List[Int](capacity=20)

    var s = 0
    for _ in range(10_000_000):
        heap.clear()
        for i in range(100):
            heap_add[lt](i * 17 % 100, heap)
            s += heap[0]
            keep(s)


def main() raises:
    print("--- heap ---")
    print(t"heap_add {round(benchmark.run[func2=bench](0, 1, 3, 6).min(Unit.s), 3)} s/1B ")
