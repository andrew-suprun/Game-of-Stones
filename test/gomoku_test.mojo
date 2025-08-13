from testing import assert_true

from score import Score, draw
from mcts import Mcts
from gomoku import Gomoku


fn test_gomoku() raises:
    alias Game = Gomoku[8]
    var game = Game()
    var tree = Mcts[Game, 10, 5, draw]()
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("i10")
    print(game)
    var best_move = String(Game.Move())
    for i in range(10_000):
        _ = tree.expand(game)
        var move = String(tree.best_move())
        if best_move != move:
            best_move = move
            print(i, best_move)

    print(tree.debug_roots())
    print("best move", tree.best_move())
    assert_true(String(tree.best_move()) == "h10")
