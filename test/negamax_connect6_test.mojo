from testing import assert_true

from game import draw
from negamax import Negamax
from connect6 import Connect6

alias C6 = Connect6[19, 12]

fn test_connect6() raises:
    var game = C6()
    var tree = Negamax[C6, 16]()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    var (score, _) = tree.expand(game, 2)
    print("best move", tree.best_move)
    print("score", score)
    assert_true(String(tree.best_move) == "i11-k9")
    assert_true(score == 13)

fn main() raises:
    for max_depth in range(1, 8):
        print("----\nDEPTH", max_depth)
        var game = C6()
        var tree = Negamax[C6, 16]()
        try:
            game.play_move("j10")
            game.play_move("i9-i10")
        except:
            pass
        var (score, pv) = tree.expand(game, max_depth)
        print("best move", tree.best_move)
        print("score", score)

        print("pv:")
        for move in pv[::-1]:
            print(move)
