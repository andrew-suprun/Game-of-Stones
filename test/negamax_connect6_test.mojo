from testing import assert_true

from score import Score, draw
from negamax import Negamax
from connect6 import Connect6

alias C6 = Connect6[max_places=12]


fn test_connect6() raises:
    var game = C6()
    var tree = Negamax[C6, 16, draw]()
    _ = game.play_move("j10")
    _ = game.play_move("i9-i10")
    print(game)
    var move = tree.search(game, 100)
    print("best move", move)
    assert_true(String(move.move) == "i11-k9")
