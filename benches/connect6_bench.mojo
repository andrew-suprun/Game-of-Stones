from benchmark import benchmark, Unit, keep

from traits import TMove, Score
from board import Board, first
from connect6 import Connect6, Move

alias C6 = Connect6[size=19, max_moves=20, max_places=12, max_plies=100]


fn bench_moves():
    var game = C6()
    try:
        _ = game.play_move("j10")
        _ = game.play_move("i9-i10")
    except:
        pass
    for _ in range(1000):
        var moves = game.moves()
        keep(moves[0].score.value)


fn main() raises:
    print("--- connect6 ---")
    print("moves   ", benchmark.run[bench_moves](0, 1, 3, 6).mean(Unit.ms), "msec")
