from benchmark import benchmark, Unit

from tree import Move, MoveScore
from tree.impl import Tree
from game_of_stones.board import Board, first
from game_of_stones.connect6 import Connect6

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

fn bench_extend():
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
    print("\n--- connect6 (ms/1000) ---")
    print("top_moves", benchmark.run[bench_top_moves]().mean(Unit.ms))
    print("extend   ", benchmark.run[bench_extend]().mean(Unit.ms))
