from testing import assert_true

from score import Score, draw
from negamax import Negamax
from connect6 import Connect6

alias C6 = Connect6[12]

fn test_connect6() raises:
    var game = C6()
    var tree = Negamax[C6, 16, draw]()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    var (score, pv) = tree.search(game, 100)
    print("best move", pv[0])
    print("score", score)
    assert_true(String(pv[0]) == "i11-k9")

fn main() raises:
    var game = C6()
    var tree = Negamax[C6, 32, draw]()
    try:
        game.play_move("j10")
        game.play_move("i9-i10")
        game.play_move("i11-k9")
    except:
        pass

    print(game)
    var (score, pv) = tree.search(game, 10)
    print("pv: ", end="")
    for move in pv:
        print(move, "", end="")

    print("| score", score)

