from testing import assert_true

from game import draw
from mcts import MCTS
from connect6 import Connect6

fn test_connect6() raises:
    alias Game = Connect6[19, 32, 20]
    var game = Game()
    var tree = MCTS[Game, 1](draw)
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    for _ in range(1000):
        # print("expand", i)
        _ = tree.expand(game)
        # print(tree)
    print(tree.debug_roots())
    print("best move", tree.best_move())
    print("decision", game.decision())
    assert_true(String(tree.best_move()) == "i11-k9")
