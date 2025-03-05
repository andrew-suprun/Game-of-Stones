from benchmark import benchmark, Unit

from game import Move, MoveScore
from connect6 import Connect6

alias C6 = Connect6[19, 60, 32]

fn bench_top_moves():
    var c6 = C6()
    try:
        c6.play_move(Move("j10"))
        c6.play_move(Move("i9-i11"))
    except:
        pass
    var moves = List[MoveScore]()
    for _ in range(1000):
        c6.top_moves(moves)
    _ = moves

def main():
    print("bench_top_moves", benchmark.run[bench_top_moves]().mean(Unit.ms))
