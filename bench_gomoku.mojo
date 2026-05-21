from std.benchmark import benchmark, Unit, keep

from engine import Mcts, Gomoku, MoveValue

comptime G = Gomoku[size=19, max_plies=100]


def bench_moves():
    var game = G()
    try:
        game.play_move({"j10"})
        game.play_move({"i9"})
    except:
        pass
    var moves = List[MoveValue[G.Move]](capacity=20)
    for _ in range(1_000_000):
        game.top_moves(32, moves)
        keep(moves[0])


def bench_expand():
    var game = G()
    var tree = Mcts[G, 0.7]()
    try:
        game.play_move({"j10"})
        game.play_move({"i9"})
    except:
        pass
    var moves = List[MoveValue[G.Move]](capacity=20)
    for _ in range(1_000_000):
        tree.expand(game, 32, moves)


def bench[f: def() thin](name: String, unit: String) raises:
    var report = benchmark.run[func2=f](0, 1, 3, 6)
    print(t"{name} {round(report.mean(Unit.s), 3)} {unit}")


def main() raises:
    print("--- gomoku ---")

    bench[bench_moves]("moves  ", "msec/1M")
    bench[bench_expand]("expand ", "msec/1M")
