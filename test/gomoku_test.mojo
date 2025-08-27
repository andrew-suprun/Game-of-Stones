from testing import assert_true

from score import Score
from mcts import Mcts
from gomoku import Gomoku


fn test_gomoku() raises:
    alias Game = Gomoku[max_places=8]
    var game = Game()
    var tree = Mcts[Game, 5]()
    _ = game.play_move("j10")
    _ = game.play_move("i9")
    _ = game.play_move("i10")
    print(game)
    for _ in range(10_000):
        _ = tree.expand(game)

    print(tree.debug_roots())
    print("best move", tree.best_move())
    assert_true(String(tree.best_move()) == "k10")
