from std.benchmark import benchmark, Unit

from heap import heap_add


def less(a: Int, b: Int) -> Bool:
    return a < b


def bench():
    var heap = List[Int](capacity=20)

    for _ in range(1_000_000):
        heap.clear()
        for i in range(100):
            heap_add[less](i * 17 % 100, heap)


def main() raises:
    print("--- heap ---")
    print("heap_add", benchmark.run[func2=bench](0, 1, 3, 6).min(Unit.ms))
