from game import draw, Decision, undecided
from connect6 import Connect6

fn main() raises:
    alias Game = Connect6[19, 8]
    var game = Game()
    game.play_move("j10")
    game.play_move("i9-i10")
    print(game)
    game.play_move("j9-j11")
    print(game)
    game.play_move("i8-i11")
    print(game)

    # game.play_move("i7-i13")
    # print(game)
    # game.play_move("j8-j12")
    # print(game)


    game.play_move("j8-j7")
    print(game)
    game.play_move("i12-i7")
    print(game)


    print(game.board.str_scores())
