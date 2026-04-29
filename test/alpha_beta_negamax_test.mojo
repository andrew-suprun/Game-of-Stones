from std.testing import assert_true
from std.time import perf_counter_ns
from std.logger import Logger

from score import Score, Win, Loss
from alpha_beta_negamax import AlphaBetaNode
from principal_variation_negamax import PrincipalVariationNode
from gomoku import Gomoku
from connect6 import Connect6

# comptime Game = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]
comptime Game = Gomoku[size=19, max_places=16, max_plies=100]

def test_build_tree() raises:
    var game = Game()


    # j10 i9 k11 i10 l8 k9
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("k11")
    game.play_move("i10")
    game.play_move("l8")
    game.play_move("k9")
    print(game)

    # var root = AlphaBetaNode[Game]({}, 0)
    var root = PrincipalVariationNode[Game]({}, 0)

    var deadline = perf_counter_ns() + UInt(60_000_000_000)

    var start = perf_counter_ns()
    for max_depth in range(1, 20):
        root.search(game, Loss, Win, 0, max_depth, deadline)
        var time = Float64(perf_counter_ns() - start) / 1_000_000_000
        var pv = List[Game.Move]()
        root._pv(pv)
        print(t"depth {max_depth}: score: {pv[0].score()} | time {time} | pv {pv}")
        # print(repr(root))
        if perf_counter_ns() > deadline:
            return
    # print(repr(root))


def main() raises:
    test_build_tree()
