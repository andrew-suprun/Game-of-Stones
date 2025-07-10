from benchmark import benchmark, Unit, keep

from game import TMove
from tree import Tree
from board import Board, first
from connect6 import Connect6, Move

alias C6 = Connect6[19, 32, 16]

fn bench_moves():
    var game = C6()
    try:
        game.play_move("j10")
        game.play_move("i9-i10")
    except:
        pass
    for _ in range(1000):
        var moves = game.moves()
        keep(moves[0][0])

fn bench_expand():
    var game = C6()
    var tree = Tree[C6, 20](C6.Score.draw())
    try:
        game.play_move(Move("j10"))
        game.play_move(Move("i9-i10"))
    except:
        pass
    for _ in range(1000):
        var done = tree.expand(game)
        keep(done)
        if done:
            print("done")
            break

fn main() raises:
    print("moves ", benchmark.run[bench_moves]().mean(Unit.ms), "msec")
    print("expand", benchmark.run[bench_expand]().mean(Unit.ms), "msec")
