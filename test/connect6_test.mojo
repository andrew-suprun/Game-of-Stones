from testing import assert_true

from tree import Tree
from connect6 import Connect6

fn test_connect6() raises:
    alias Game = Connect6[19, 32, 20]
    var game = Game()
    var tree = Tree[Game, 1]()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    for _ in range(1000):
        _ = tree.expand(game)
        # print("expand", i)
        # print(tree)
    tree.debug_best_moves()
    print("best move", tree.best_move())
    print("decision", game.decision())
    assert_true(String(tree.best_move()) == "i11-k9")
