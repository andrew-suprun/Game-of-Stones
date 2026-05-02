from std.testing import assert_true
from std.time import perf_counter_ns
from std.logger import Logger
from std.reflection import reflect


from traits import TGame
from score import Score, Win, Loss
from alpha_beta_negamax import AlphaBetaNode
from gomoku import Gomoku
from connect6 import Connect6

comptime C6 = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]
comptime G = Gomoku[size=19, max_places=16, max_plies=100]


def bench_build_tree[Game: TGame](max_depth: Int) raises:
    var game = Game()

    game.play_move(Game.Move("j10"))
    game.play_move(Game.Move("i9"))
    game.play_move(Game.Move("k11"))
    game.play_move(Game.Move("i10"))
    game.play_move(Game.Move("l8"))
    game.play_move(Game.Move("k9"))
    # print(game)

    print(t"\nGame: {reflect[Game]().base_name()}")

    var root = AlphaBetaNode[Game]({}, 0)

    var deadline = perf_counter_ns() + UInt(60_000_000_000)

    var start = perf_counter_ns()
    for max_depth in range(1, max_depth + 1):
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
    bench_build_tree[G](13)
    bench_build_tree[C6](10)
