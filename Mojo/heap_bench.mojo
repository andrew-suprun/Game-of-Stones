from benchmark import benchmark, Unit

from heap import add


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


def main():
    print("heap bench    ", benchmark.run[bench]().mean(Unit.ns))
