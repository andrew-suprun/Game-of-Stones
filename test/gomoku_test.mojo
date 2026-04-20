from std.testing import assert_true
from std.time import perf_counter_ns

from traits import Score
from mcts import Mcts
from gomoku import Gomoku


def main() raises:
    comptime Game = Gomoku[size=19, max_places=8, max_plies=100]
    var game = Game()
    var tree = Mcts[Game, 2]()
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("i10")
    print(game)
    var result = tree.search(game, 1000)
    print("pv:", len(result), result)
    print(tree.debug_roots())
    assert_true(String(result[0]) == "h10")
