from benchmark import benchmark, Unit

from tree import Tree
from game import Move, MoveScore
from gomoku import Gomoku

alias G = Gomoku[19, 32]

fn bench_top_moves():
    var game = G()
    try:
        game.play_move(Move("j10"))
        game.play_move(Move("i9"))
    except:
        pass
    var moves = List[MoveScore]()
    for _ in range(1000):
        game.top_moves(moves)
    _ = moves

fn bench_extend():
    var game = G()
    var tree = Tree[G](20)
    try:
        game.play_move(Move("j10"))
        game.play_move(Move("i9"))
    except:
        pass
    for _ in range(100_000):
        var done = tree.expand(game)
        if done:
            print("done")
            break

fn main() raises:
    # print("bench_top_moves", benchmark.run[bench_top_moves]().mean(Unit.ms))
    print("bench_extend   ", benchmark.run[bench_extend]().mean(Unit.ms))
