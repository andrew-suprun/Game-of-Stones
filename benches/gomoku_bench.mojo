from benchmark import benchmark, Unit, keep

from score import Score, draw
from game import TMove
from mcts import Mcts
from gomoku import Gomoku

alias G = Gomoku[max_places=32]


fn bench_moves():
    var game = G()
    try:
        game.play_move(Gomoku.Move("j10"))
        game.play_move(Gomoku.Move("i9"))
    except:
        pass
    for _ in range(1000):
        var moves = game.moves(32)
        keep(moves[0].move)


fn bench_expand():
    var game = G()
    var tree = Mcts[G, 20, 20, draw]()
    try:
        game.play_move(Gomoku.Move("j10"))
        game.play_move(Gomoku.Move("i9"))
    except:
        pass
    for _ in range(1000):
        var done = tree.expand(game)
        if done:
            print("done")
            break


fn main() raises:
    print("--- gomoku ---")
    print("moves ", benchmark.run[bench_moves]().mean(Unit.ms), "msec")
    print("expand", benchmark.run[bench_expand]().mean(Unit.ms), "msec")
