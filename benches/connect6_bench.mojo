from benchmark import benchmark, Unit, keep

from game import TMove, Score
from negamax import Negamax
from board import Board, first
from connect6 import Connect6, Move

alias C6 = Connect6[max_moves=20, max_places=12]


fn bench_moves():
    var game = C6()
    try:
        _ = game.play_move("j10")
        _ = game.play_move("i9-i10")
    except:
        pass
    for _ in range(1000):
        var moves = game.moves()
        keep(moves[0].score)


fn main() raises:
    print("--- connect6 ---")
    print("moves   ", benchmark.run[bench_moves]().mean(Unit.ms), "msec")
