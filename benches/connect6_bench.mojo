from benchmark import benchmark, Unit, keep

from game import TMove, Score
from tree import Tree
from board import Board, first
from connect6 import Connect6, Move

alias C6 = Connect6[19, 60, 32]

fn bench_moves():
    var c6 = C6()
    try:
        c6.play_move("j10")
        c6.play_move("i9-i10")
    except:
        pass
    for _ in range(1000):
        var moves = c6.moves()
        keep(moves[0])

fn bench_expand():
    var game = C6()
    var tree = Tree[C6, 20]()
    try:
        game.play_move(Move("j10"))
        game.play_move(Move("i9-i10"))
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
