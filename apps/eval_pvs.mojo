from time import perf_counter_ns
from logger import Logger

from traits import MoveScore
from score import Score
from connect6 import Connect6

from mcts import Mcts
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNode

comptime Game = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]

comptime script = "j10 i9-i10"
comptime max_depth = 9
comptime duration_ms = 300_000


fn main() raises:
    for depth in range(0, max_depth):
        var game = Game()
        var best_move = MoveScore(Game.Move(), Score.loss())
        print(best_move)
        for move_str in script.split(" "):
            _ = game.play_move(Game.Move(String(move_str)))
        print("depth", depth, script)
        print(game)
        var root = PrincipalVariationNode[Game](Game.Move(), Score())
        start = perf_counter_ns()
        deadline = start + UInt(1_000_000) * duration_ms
        _ = root._search(game, best_move, Score.loss(), Score.win(), 0, depth, deadline, Logger(prefix="pvs: "))
        print("search result:", best_move, "time:", Float64(perf_counter_ns() - start) / 1_000_000_000)
        for child in root.children:
            print(" ", child.move, child.score)
        # print(root)
