from benchmark import benchmark, Unit, keep

from game import TMove, draw
from negamax import Negamax
from board import Board, first
from connect6 import Connect6, Move

alias C6 = Connect6[19, 12]

fn bench_moves():
    var game = C6()
    try:
        game.play_move("j10")
        game.play_move("i9-i10")
    except:
        pass
    for _ in range(1000):
        var moves = game.moves(16)
        keep(moves[0][1])

fn bench_expand[depth: Int]():
    var game = C6()
    var tree = Negamax[C6, 16]()
    try:
        game.play_move(Move("j10"))
        game.play_move(Move("i9-i10"))
    except:
        pass
    var score = tree.expand(game, depth)
    keep(score[0])

fn main() raises:
    print("moves   ", benchmark.run[bench_moves]().mean(Unit.ms), "msec")
    @parameter
    for i in range(2, 8):
        print("expand-", i, " ", benchmark.run[bench_expand[i]]().mean(Unit.ms), " msec", sep="")
