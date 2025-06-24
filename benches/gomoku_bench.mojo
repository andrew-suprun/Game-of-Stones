from benchmark import benchmark, Unit, keep

from game import TMove, TScore
from tree import Tree
from gomoku import Gomoku

alias G = Gomoku[19, 22]

fn bench_moves():
    var game = G()
    try:
        game.play_move(Gomoku.Move("j10"))
        game.play_move(Gomoku.Move("i9"))
    except:
        pass
    for _ in range(1000):
        var moves = game.moves()
        keep(moves[0])

fn bench_expand():
    var game = G()
    var tree = Tree[G, 20]()
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
    print("moves ", benchmark.run[bench_moves]().mean(Unit.ms), "msec")
    print("expand", benchmark.run[bench_expand]().mean(Unit.ms), "msec")
