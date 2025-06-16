from benchmark import benchmark, Unit

from game import Move, Score
from tree import Tree
from game_of_stones.board import Board, first
from game_of_stones import Connect6

alias C6 = Connect6[19, 60, 32]

fn bench_top_moves():
    var c6 = C6()
    try:
        c6.play_move(Move("j10"))
        c6.play_move(Move("i9-i10"))
    except:
        pass
    var moves = List[Move]()
    for _ in range(1000):
        c6.top_moves(moves)
    _ = moves

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
    print("top_moves", benchmark.run[bench_top_moves]().mean(Unit.s), "msec")
    print("expand   ", benchmark.run[bench_expand]().mean(Unit.s), "msec")
