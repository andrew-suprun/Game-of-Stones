from std.benchmark import benchmark, Unit, black_box, keep
from std.logger import Logger, Level

from config import Assert


def fib(n: Int) -> Int:
    if n < 2:
        return n
    return fib(n-1) + fib(n-2)

def bench_fib():
        keep(fib(black_box(40)) > 100_000_000)


def bench_assert_fib():
    assert fib(black_box(40)) > 100_000_000


def bench_assert_assert():
    comptime if Assert:
        assert fib(black_box(40)) > 100_000_000


def main() raises:
    print("--- assert ---")
    print("bench_fib          ", benchmark.run[func2=bench_fib](0, 1, 3, 6).min(Unit.ms))
    print("bench_assert_fib   ", benchmark.run[func2=bench_assert_fib](0, 1, 3, 6).min(Unit.ms))
    print("bench_assert_assert", benchmark.run[func2=bench_assert_assert](0, 1, 3, 6).min(Unit.ms))
