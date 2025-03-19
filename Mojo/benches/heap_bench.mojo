from benchmark import benchmark, Unit

from game_of_stones.heap import add


fn bench():
    @parameter
    fn less(a: Int, b: Int, out r: Bool):
        r = a < b

    var heap = List[Int]()
    var values = List[Int]()
    for i in range(100):
        values.append(100 - i)

    for _ in range(1000):
        for i in range(100):
            add[Int, 20, less](values[i], heap)


fn main() raises:
    print("\n--- heap (ms/100_000) ---")
    print("add", benchmark.run[bench]().mean(Unit.ms))
