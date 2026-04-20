from std.testing import assert_true
from std.time import perf_counter_ns

from traits import Score
from mcts import Mcts
from gomoku import Gomoku
from connect6 import Connect6


def test_gomoku() raises:
    comptime Game = Gomoku[size=19, max_places=8, max_plies=100]
    var game = Game()
    var tree = Mcts[Game, 16]()
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("i10")
    print(game)
    var result = tree.search(game, 1000)
    print("pv:", len(result), result)
    print(tree.debug_roots())
    assert_true(String(result[0]) == "k10")

def test_connect6() raises:
    comptime Game = Connect6[size=19, max_moves=8, max_places=6, max_plies=100]
    var game = Game()
    var tree = Mcts[Game, 16]()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    var result = tree.search(game, 1000)
    print("pv:", len(result), result)
    print(tree.debug_roots())
    assert_true(String(result[0]) == "i11-k9")

def main() raises:
    test_gomoku()
    test_connect6()