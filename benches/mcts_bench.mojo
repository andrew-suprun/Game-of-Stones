from std.time import perf_counter_ns
from std.reflection import reflect

from traits import TGame
from score import Score, Win, Loss
from mcts import Mcts
from gomoku import Gomoku
from connect6 import Connect6

comptime C6 = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]
comptime G = Gomoku[size=19, max_places=16, max_plies=100]


def bench_build_tree[Game: TGame]() raises:
    var game = Game()

    game.play_move(Game.Move("j10"))
    game.play_move(Game.Move("i9"))
    game.play_move(Game.Move("k11"))
    game.play_move(Game.Move("i10"))
    game.play_move(Game.Move("l8"))

    print(t"\nGame: {reflect[Game]().base_name()}")

    var tree = Mcts[Game, 0.7]()
    var start = perf_counter_ns()
    var deadline = start + UInt(10_000_000_000)
    var count = 0
    while perf_counter_ns() < deadline:
        tree.expand(game)
        count += 1

    var pv = tree._pv()
    print(t"score: {pv[0].score()} | expands/sec {count/10} | pv {pv}")


def main() raises:
    bench_build_tree[G]()
    bench_build_tree[C6]()
