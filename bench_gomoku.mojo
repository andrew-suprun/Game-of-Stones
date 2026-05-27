from std.benchmark import benchmark, Unit, keep

from engine import Mcts, Gomoku, Score, MoveScore

comptime G = Gomoku[size=19, max_moves=20]


def bench_moves():
    var game = G()
    try:
        game.play_move({"j10"})
        game.play_move({"i9"})
    except:
        pass
    for _ in range(1_000_000):
        var moves = game.top_moves()
        keep(moves[0])


def bench_expand():
    var game = G()
    var tree = Mcts[G, Score(0.25)]()
    try:
        game.play_move({"j10"})
        game.play_move({"i9"})
    except:
        pass
    for _ in range(1_000_000):
        keep(tree.expand(game))


def bench[f: def() thin](name: String, unit: String) raises:
    var report = benchmark.run[func2=f](0, 1, 3, 6)
    print(t"{name} {round(report.mean(Unit.s), 3)} {unit}")


def main() raises:
    print("--- gomoku ---")

    bench[bench_moves]("moves  ", "msec/1M")
    bench[bench_expand]("expand ", "msec/1M")
