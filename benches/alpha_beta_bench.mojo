import benchmark
from time import perf_counter_ns

from game import Score
from search import AlphaBetaNegamax
from connect6 import Connect6

alias C6 = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]


fn bench_full_window():
    game = C6()
    try:
        _ = game.play_move("j10")
        _ = game.play_move("j9-i10")
    except:
        pass
    var tree = AlphaBetaNegamax[C6]()
    var start = perf_counter_ns()
    var score = tree._search(game, 23, 88, 0, 5, perf_counter_ns() + 20_000_000_000)
    print("score", score, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)


fn main() raises:
    print("--- 23-88 ---")
    var report = benchmark.run[bench_full_window]()
    print("25-25", report.mean(benchmark.Unit.ms), "msec")
    report.print_full()
