from benchmark import benchmark, Unit

from heap import Heap


fn less(a: Int, b: Int) -> Bool:
    return a < b


fn bench():
    var h = heap.Heap[Int, 20, less]()

    for _ in range(1_000_000):
        h.clear()
        for i in range(100):
            h.add(i * 17 % 100)


fn main() raises:
    print("--- heap ---")
    print("heap_add", benchmark.run[func1=bench](0, 1, 3, 6).min(Unit.ms))
