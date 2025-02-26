from random import seed, random_si64

from board import Board
from game import Place
from connect6 import max_stones, value_table, values


def test_place_stone():
    seed(0)
    var board = Board[19, max_stones]()
    var value = Float32(0)
    for i in range(200):
        # print(board)
        # print(board.str_values())
        board.turn = Int(random_si64(0, 1))
        var x = Int(random_si64(0, board.size - 1))
        var y = Int(random_si64(0, board.size - 1))
        print("=== playing:", i, Place(x, y), board.turn)
        if board[x, y] == board.empty:
            var failure = False
            for y in range(board.size):
                for x in range(board.size):
                    if board[x, y] == board.empty:
                        var actual = board.getvalue(x, y)
                        var copy = board.copy()
                        copy.turn = 0
                        copy.place_stone(Place(x, y), value_table)
                        var expected = copy.debug_board_value(values)[0] - value
                        if actual[0] != expected:
                            failure = True
                            print(
                                "X",
                                Place(x, y),
                                "actial",
                                actual[0],
                                "expected",
                                expected,
                            )
                        copy = board.copy()
                        copy.turn = 1
                        copy.place_stone(Place(x, y), value_table)
                        expected = copy.debug_board_value(values)[1] - value
                        if actual[1] != expected:
                            failure = True
                            print(
                                "O",
                                Place(x, y),
                                "actial",
                                actual[1],
                                "expected",
                                expected,
                            )
            if failure:
                print(board)
                print(board.str_values())
                return
            value += board.getvalue(x, y)[board.turn]
            board.place_stone(Place(x, y), value_table)
