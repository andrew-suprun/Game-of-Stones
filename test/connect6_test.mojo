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
    for i in range(1, 101):
        _ = tree.expand(game)
        print("expand", i)
        print(tree)
    print("score", tree.score())
    assert_true(tree.score() == 58)
