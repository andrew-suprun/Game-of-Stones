from engine import BoardA, Place, black, white


def test_board() raises:
    var board = BoardA()
    board.place_stone("j10", black)
    board.place_stone("i10", white)
    board.place_stone("b13", black)
    print(board)
    board.top_moves()


def main() raises:
    test_board()
