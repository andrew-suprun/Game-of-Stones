from std.benchmark import benchmark, Unit, keep

from traits import TMove
from mcts import Mcts
from gomoku import Gomoku

comptime G = Gomoku[size=19, max_places=32, max_plies=100]


def bench_moves():
    var game = G()
    try:
        game.play_move({"j10"})
        game.play_move({"i9"})
    except:
        pass
    for _ in range(1_000_000):
        var moves = game.moves()
        keep(moves[0])


def bench_expand():
    var game = G()
    var tree = Mcts[G, 0.7]()
    try:
        game.play_move({"j10"})
        game.play_move({"i9"})
    except:
        pass
    for _ in range(1_000_000):
        tree.expand(game)


def bench[f: def() thin](name: String, unit: String) raises:
    var report = benchmark.run[func2=f](0, 1, 3, 6)
    print(t"{name} {round(report.mean(Unit.s), 3)} {unit}")


def main() raises:
    print("--- gomoku ---")

    bench[bench_moves]("moves  ", "msec/1M")
    bench[bench_expand]("expand ", "msec/1M")
