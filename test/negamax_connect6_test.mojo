from testing import assert_true

from game import draw
from negamax import Negamax
from connect6 import Connect6

fn test_connect6() raises:
    alias Game = Connect6[19, 8, 8]
    var game = Game()
    var tree = Negamax[Game]()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    var score = tree.expand(game, 2)
    print("best move", tree.best_move)
    print("score", score)
    assert_true(False)
