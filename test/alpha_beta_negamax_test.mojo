from std.testing import assert_true
from std.time import perf_counter_ns

from alpha_beta_negamax import AlphaBetaNode
from connect6 import Connect6

comptime Game = Connect6[size=19, max_moves=8, max_places=12, max_plies=100]

def test_build_tree() raises:
    var game = Game()

    game.play_move("j10")       #1
    game.play_move("j9-i10")    #2
    game.play_move("j8-i8")     #3
    game.play_move("j12-h12")   #4
    game.play_move("h8-k8")     #5
    game.play_move("f8-l8")     #6
    game.play_move("f8-l8")     #6
    game.play_move("i9-k11")    #7
    game.play_move("g7-l12")    #8
    game.play_move("k7-l6")     #9
    game.play_move("h10-m5")    #10
    game.play_move("k6-k9")    #11

    var root = AlphaBetaNode[Game]({})
    var deadline = perf_counter_ns() + UInt(20_000_000)

    for max_depth in range(1, 7):
        done = root._search(game, -Game.Win, Game.Win, 0, max_depth, deadline)
        print(t"==== max depth {max_depth}; done: {done}")
        print(root)

def main() raises:
    test_build_tree()
