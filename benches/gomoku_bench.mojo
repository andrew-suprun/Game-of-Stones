from benchmark import benchmark, Unit, keep

from score import Score
from traits import TMove
from mcts import Mcts
from gomoku import Gomoku

comptime G = Gomoku[size=19, max_places=32, max_plies=100]


fn bench_moves():
    var game = G()
    try:
        _ = game.play_move(Gomoku.Move("j10"))
        _ = game.play_move(Gomoku.Move("i9"))
    except:
        pass
    for _ in range(1000):
        var moves = game.moves()
        keep(moves[0].move)


fn bench_expand():
    var game = G()
    var tree = Mcts[G, 8]()
    try:
        _ = game.play_move(Gomoku.Move("j10"))
        _ = game.play_move(Gomoku.Move("i9"))
    except:
        pass
    for _ in range(1000):
        var done = tree.expand(game)
        if done:
            print("done")
            break


fn main() raises:
    print("--- gomoku ---")
    print("moves ", benchmark.run[bench_moves](0, 1, 3, 6).mean(Unit.ms), "msec")
    print("expand", benchmark.run[bench_expand](0, 1, 3, 6).mean(Unit.ms), "msec")
