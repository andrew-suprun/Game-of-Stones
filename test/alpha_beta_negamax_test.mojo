from std.testing import assert_true
from std.time import perf_counter_ns
from std.logger import Logger

from traits import Score
from alpha_beta_negamax import AlphaBetaNode
from connect6 import Connect6

comptime Game = Connect6[size=19, max_moves=8, max_places=12, max_plies=100]

def test_build_tree() raises:
    var game = Game()

    game.play_move("j10")       #1
    game.play_move("i9-j11")     #2
    print(game)

    var root = AlphaBetaNode[Game]({}, 0)
    var deadline = perf_counter_ns() + UInt(60_000_000_000)
    var logger = Logger[]()

    var start = perf_counter_ns()
    for max_depth in range(1, 20):
        print(t"==== start max depth {max_depth}")
        done = root._search(game, -Game.Win, Game.Win, 0, max_depth, deadline)
        var time = Float64(perf_counter_ns() - start) / 1_000_000_000
        print(t"==== end max depth {max_depth}; done: {done} time {time}")
        # print(root)

def main() raises:
    test_build_tree()
