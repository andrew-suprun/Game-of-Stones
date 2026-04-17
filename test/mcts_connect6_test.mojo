from std.testing import assert_true

from traits import Score
from mcts import Mcts
from connect6 import Connect6


def test_connect6() raises:
    comptime Game = Connect6[size=19, max_moves=32, max_places=20, max_plies=100]
    var game = Game()
    var tree = Mcts[Game, 8]()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    for _ in range(1000):
        _ = tree.expand(game)
    # print(tree.debug_roots())
    # print(tree)
    print("best move", tree.best_move())
    assert_true(String(tree.best_move()) == "i11-k9")


def main() raises:
    comptime Game = Connect6[size=19, max_moves=8, max_places=6, max_plies=100]
    var game = Game()
    var tree = Mcts[Game, 8]()
    game.play_move("j10")
    game.play_move("i9-i10")
    for _ in range(2):
        print(game)
        for _ in range(20):
            if tree.expand(game):
                break
        print("best move", tree.best_move())
        game.play_move(tree.best_move())
        print(tree.debug_roots())
        tree = Mcts[Game, 8]()
