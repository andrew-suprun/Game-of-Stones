from std.benchmark import benchmark, Unit, keep, black_box


def f(n: Int) -> Int:
    if n < 2:
        return n
    return f(n - 1) + f(n - 2)


def bench_assert1():
    for _ in range(1_000_000_000):
        assert black_box(f(44) > 1000)


def bench_assert2():
    def a() capturing -> Bool:
        return black_box(f(44) > 1000)

    for _ in range(1_000_000_000):
        debug_assert[a]()


def main() raises:
    print(t"assert1 {round(benchmark.run[func2=bench_assert1](0, 1, 3, 6).min(Unit.s), 3)} s/1B ")
    print(t"assert2 {round(benchmark.run[func2=bench_assert2](0, 1, 3, 6).min(Unit.s), 3)} s/1B ")
