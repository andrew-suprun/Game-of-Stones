from std.time import perf_counter_ns
from std.benchmark import benchmark, Unit, keep

def bench_perf_counter():
    for _ in range(1_000_000):
        keep(perf_counter_ns)


def main() raises:
    print("--- perf_counter ---")
    print("perf_counter", benchmark.run[func2=bench_perf_counter](0, 1, 3, 6).mean(Unit.ms))
