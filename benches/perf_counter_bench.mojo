from std.benchmark import benchmark, Unit, keep
from std.time import perf_counter_ns


def bench():
    var s: UInt = 0
    for _ in range(500_000):
        start = perf_counter_ns()
        end = perf_counter_ns()
        s += end - start
        keep(s)


def main() raises:
    print("--- perf_counter ---")
    print(t"perf_counter: {round(benchmark.run[func2=bench](0, 1, 3, 6).mean(Unit.ms), 3)} msec/1M")
