from benchmark import benchmark, Unit

from game_of_stones.heap import add, Heap


fn less(a: Int, b: Int, out r: Bool) capturing:
    r = a < b


fn bench():
    var heap = List[Int]()

    for _ in range(1_000_000):
        heap.clear()
        for i in range(100):
            add[Int, 20, less](i * 17 % 100, heap)


fn bench2():
    var heap = Heap[Int, 20, less]()

    for _ in range(1_000_000):
        heap.len = 0
        for i in range(100):
            heap.add(i * 17 % 100)


fn main() raises:
    print("\n--- heap (s/100_000_000) ---")
    print("add ", benchmark.run[bench]().min(Unit.s))
    print("heap", benchmark.run[bench2]().min(Unit.s))
