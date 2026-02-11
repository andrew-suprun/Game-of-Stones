from benchmark import benchmark, Unit, keep
from logger import Logger, Level


fn bench1():
    var logger = Logger()
    var s = 0
    for _ in range(1_000_000):
        for i in range(100):
            logger.trace("|   " * i)
            s += i
    keep(s)


fn bench2():
    var logger = Logger()
    var s = 0
    for _ in range(1_000_000):
        for i in range(100):
            if logger.level >= Level.TRACE:
                logger.trace("|   " * i)
            s += i
    keep(s)


fn main() raises:
    print("--- logger ---")
    print("bench1", benchmark.run[func2=bench1](0, 1, 3, 6).min(Unit.ms))
    print("bench2", benchmark.run[func2=bench2](0, 1, 3, 6).min(Unit.ms))
