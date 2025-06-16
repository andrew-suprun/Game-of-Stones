from benchmark import benchmark, Unit

from game import Move, Score
from tree import Tree
from game_of_stones import Gomoku

alias G = Gomoku[19, 32]

fn bench_top_moves():
    var game = G()
    try:
        game.play_move(Move("j10"))
        game.play_move(Move("i9"))
    except:
        pass
    var moves = List[Move]()
    for _ in range(1000):
        game.top_moves(moves)
    _ = moves

fn bench_expand():
    var game = G()
    var tree = Tree[G, 20]()
    try:
        game.play_move(Move("j10"))
        game.play_move(Move("i9"))
    except:
        pass
    for _ in range(1000):
        var done = tree.expand(game)
        if done:
            print("done")
            break

fn main() raises:
    print("top_moves", benchmark.run[bench_top_moves]().mean(Unit.s), "msec")
    print("expand   ", benchmark.run[bench_expand]().mean(Unit.s), "msec")
