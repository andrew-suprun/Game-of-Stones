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
    var (score, pv) = tree.search(game, 1000)
    print("best move", pv[0])
    print("score", score)
    assert_true(String(pv[0]) == "i11-k9")
    assert_true(score == 18)

fn main() raises:
    for duration in [10, 100, 1000, 5000, 20_000, 60_000, 180_000]:
        var game = C6()
        var tree = Negamax[C6, 32]()
        try:
            game.play_move("j10")
            game.play_move("i9-i10")
        except:
            pass
        var (score, pv) = tree.search(game, duration)
        print("duration", String(duration).rjust(5, " "), end="")
        print(": score", score, end="")

        print(" pv: ", end="")
        for move in pv:
            print(move, "", end="")
        print()
