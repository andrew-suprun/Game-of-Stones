from benchmark import benchmark, Unit

from heap import heap_add


fn less(a: Int, b: Int, out r: Bool) capturing:
    r = a < b


fn bench():
    var heap = List[Int]()

    for _ in range(1_000_000):
        heap.clear()
        for i in range(100):
            heap_add[Int, 20, less](i * 17 % 100, heap)


fn main() raises:
    print("\n--- heap (s/100_000_000) ---")
    print("heap_add", benchmark.run[bench]().min(Unit.s))
