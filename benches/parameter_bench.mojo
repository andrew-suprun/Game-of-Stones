from time import perf_counter_ns

fn f1[b: Bool](c: Int) -> Int:
    var s = 0
    for _ in range(c):
        if b:
            s += 1
        else:
            s += 2
    return s

fn f2[b: Bool](c: Int) -> Int:
    var s = 0
    for _ in range(c):
        @parameter
        if b:
            s += 1
        else:
            s += 2
    return s

fn f3(b: Bool, c: Int) -> Int:
    var s = 0
    for _ in range(c):
        if b:
            s += 1
        else:
            s += 2
    return s

fn main() raises:
    var c = 100_000_000
    var b = True

    for _ in range(5):
        var t1 = perf_counter_ns()
        var b1 = f1[True](c)
        var t2 = perf_counter_ns()
        print("b1", b1, t2-t1)

    print()

    for _ in range(5):
        var t3 = perf_counter_ns()
        var b2 = f2[True](c)
        var t4 = perf_counter_ns()
        print("b2", b2, t4-t3)

    print()

    for _ in range(5):
        var t5 = perf_counter_ns()
        var b3 = f3(b, c)
        var t6 = perf_counter_ns()
        print("b3", b3, t6-t5)