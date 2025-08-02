from game import draw, Decision, undecided
from connect6 import Connect6

fn main() raises:
    alias Game = Connect6[19, 8]
    var game = Game()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    game.play_move("i11-k9")
    print(game)
    game.play_move("i6-i5")
    print(game)
    game.play_move("h12-l8")
    print(game)

    print(game.board.str_scores())
