from std.benchmark import benchmark, Unit, keep, black_box


def bench_reduce_max():
    # var v: SIMD[DType.int8, 8] = [1, 2, 3, 4, 5, 6, 7, 8]
    # print(v.reduce_max[1]())
    # print(v.reduce_add[1]())
    # print(v.reduce_max[2]())
    # print(v.reduce_add[2]())

    var heap = List[SIMD[DType.int8, 8]](length=1000, fill=[0, 0, 0, 0, 0, 0, 0, 0])
    for _ in range(1_000_000):
        for i in range(1000):
            ref v = black_box(heap[i])
            keep(v.reduce_max[1]())


def bench_reduce_add():
    var heap = List[SIMD[DType.int8, 8]](length=1000, fill=[0, 0, 0, 0, 0, 0, 0, 0])
    for _ in range(1_000_000):
        for i in range(1000):
            ref v = black_box(heap[i])
            keep(v.reduce_add[2]())


def bench_reduce_or():
    var heap = List[SIMD[DType.int8, 8]](length=1000, fill=[0, 0, 0, 0, 0, 0, 0, 0])
    for _ in range(1_000_000):
        for i in range(1000):
            ref v = black_box(heap[i])
            keep(v.reduce_or[2]())


def bench_reduce_or2():
    var heap = List[SIMD[DType.int16, 4]](length=1000, fill=[0, 0, 0, 0])
    for _ in range(1_000_000):
        for i in range(1000):
            ref v = black_box(heap[i])
            keep(v.reduce_or())


def main() raises:
    print("--- reduce ---")
    print(t"reduce_max {round(benchmark.run[func2=bench_reduce_max](0, 1, 3, 6).min(Unit.s), 3)} s/1B ")
    print(t"reduce_add {round(benchmark.run[func2=bench_reduce_add](0, 1, 3, 6).min(Unit.s), 3)} s/1B ")
    print(t"reduce_or  {round(benchmark.run[func2=bench_reduce_or](0, 1, 3, 6).min(Unit.s), 3)} s/1B ")
    print(t"reduce_or2 {round(benchmark.run[func2=bench_reduce_or2](0, 1, 3, 6).min(Unit.s), 3)} s/1B ")
