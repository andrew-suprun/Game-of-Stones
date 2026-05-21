from std.time import perf_counter_ns

from engine import Gomoku, Connect6, Mcts
from engine import AlphaBetaNegamax, PrincipalVariationNegamax

comptime Game = Connect6[size=19, max_plies=100]
# comptime Game = Gomoku[size=19, max_plies=100]

# comptime Tree = Mcts[Game, 0.35]
comptime Tree = AlphaBetaNegamax[Game]
# comptime Tree = PrincipalVariationNegamax[Game]

comptime script = "j10 j11-l10 i10-h10 j9-i8 h12-k8 k10-l11 h7-n13 l8-l9 l7-l12 k11-m11 h11-n11 h9-k9 e10-i9 g10-m9 k7-n9"


def main() raises:
    var game = Tree.Game()
    var tree = Tree()
    var open_moves = script.split(" ")
    print("opening", script)
    for move_str in open_moves:
        game.play_move({String(move_str)})
    print(game)

    var start = perf_counter_ns()
    var pv = tree.search(game, 20, 250)
    print("search result", pv, "time.ms", Float64(perf_counter_ns() - start) / 1_000_000)
    # print(repr(tree))
