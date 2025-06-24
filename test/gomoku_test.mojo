from testing import assert_true

from tree import Tree
from gomoku import Gomoku

fn test_gomoku() raises:
    alias Game = Gomoku[19, 6]
    var game = Game()
    var tree = Tree[Game, 30]()
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("i10")
    print(game)
    for _ in range(4):
        _ = tree.expand(game)
        print(tree)
    print("score", tree.score())
    assert_true(tree.score().value() == 30)