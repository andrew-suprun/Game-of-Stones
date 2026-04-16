from std.testing import assert_true
from std.time import perf_counter_ns

from traits import Score
from mcts import Mcts
from gomoku import Gomoku


def main() raises:
    comptime Game = Gomoku[size=19, max_places=8, max_plies=100]
    var game = Game()
    var tree = Mcts[Game, 16]()
    _ = game.play_move("j10")
    _ = game.play_move("i9")
    _ = game.play_move("i10")
    print(game)
    var result = tree.search(game, 1000)
    print(result)
    print(tree.debug_roots())
    print("best move", tree.best_move())
    assert_true(String(result.move) == "k10")
