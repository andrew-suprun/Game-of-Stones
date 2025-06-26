from testing import assert_true

from tree import Tree
from connect6 import Connect6

fn test_connect6() raises:
    alias Game = Connect6[19, 6, 6]
    var game = Game()
    var tree = Tree[Game, 30]()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    for _ in range(4):
        _ = tree.expand(game)
    print(tree)
    print("score", tree.score())
    assert_true(tree.score() == 58)
