from testing import assert_true

from score import Score, draw
from mcts import Mcts
from connect6 import Connect6


fn test_connect6() raises:
    alias Game = Connect6[max_places=20]
    var game = Game()
    var tree = Mcts[Game, 32, 1, draw]()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    for _ in range(1000):
        _ = tree.expand(game)
    # print(tree.debug_roots())
    # print(tree)
    print("best move", tree.best_move())
    print("score", game.score())
    assert_true(String(tree.best_move()) == "i11-k9")


fn main() raises:
    alias Game = Connect6[max_places=6]
    var game = Game()
    var tree = Mcts[Game, 8, 5, draw]()
    game.play_move("j10")
    game.play_move("i9-i10")
    for _ in range(2):
        print(game)
        for _ in range(20):
            _ = tree.expand(game)
        print("best move", tree.best_move())
        game.play_move(tree.best_move())
        print("score", game.score())
        print(tree)
        print(tree.debug_roots())
        if game.is_terminal():
            break
        tree = Mcts[Game, 8, 5, draw]()
