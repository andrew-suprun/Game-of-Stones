from benchmark import benchmark, Unit

from game_of_stones.heap import add


fn bench():
    @parameter
    fn less(a: Int, b: Int, out r: Bool):
        r = a < b

    var heap = List[Int]()

    for _ in range(1_000_000):
        heap.clear()
        for i in range(100):
            add[Int, 20, less](100 - i, heap)


fn main() raises:
    print("\n--- heap (s/100_000_000) ---")
    print("add", benchmark.run[bench]().mean(Unit.s))
