from engine import BoardA, Place, black, white


def test_board() raises:
    var board = BoardA()
    board.place_stone("j10", black)
    board.place_stone("f10", white)
    board.place_stone("h10", white)
    board.place_stone("k10", black)
    print(board)
    board.top_moves()


def main() raises:
    test_board()
