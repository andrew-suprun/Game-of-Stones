from connect6 import Connect6


def main() raises:
    comptime C6 = Connect6[size=19, max_moves=20, max_places=16, max_plies=100]

    var game = C6()
    game.play_move(C6.Move("j10"))
    game.play_move(C6.Move("i9-i10"))

    var moves = game.moves()
    print(len(moves))
    for move in moves:
        print(repr(move))
