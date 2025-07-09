from testing import assert_true

from tree import Tree
from gomoku import Gomoku

fn test_gomoku() raises:
    alias Game = Gomoku[19, 8]
    var game = Game()
    var tree = Tree[Game, 10]()
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("i10")
    print(game)
    var best_move = Game.Move("a1")
    for i in range(10_000):
        _ = tree.expand(game)
        var move = tree.best_move()
        if best_move != move:
            best_move = move
            print(i, best_move)

    tree.debug_roots()
    print("best move", tree.best_move())
    assert_true(String(tree.best_move()) == "h10")
