from random import seed, random_si64

from scores import Score
from board import Board
from game import Place
from connect6 import max_stones, value_table, values


def test_place_stone():
    seed(0)
    var board = Board[19, max_stones]()
    var value = Score(0)
    for i in range(200):
        print(board)
        print(board.str_values())
        board.turn = Int(random_si64(0, 1))
        var x = Int(random_si64(0, board.size - 1))
        var y = Int(random_si64(0, board.size - 1))
        print("=== playing:", i, Place(x, y), board.turn)
        board.place_stone(Place(x, y), 1, value_table[0])
        print(board)
        print(board.str_values())
        board.place_stone(Place(x, y), -1, value_table[0])
        if board[x, y] == board.empty:
            var failure = False
            for y in range(board.size):
                for x in range(board.size):
                    if board[x, y] == board.empty:
                        print("#1.1")
                        var actual = board.getvalue(x, y)
                        board.turn = 0
                        print("#1.2")
                        board.place_stone(Place(x, y), 1, value_table[0])
                        print("#1.3")
                        var expected = board.debug_board_value(values) - value
                        print("#1.4")
                        board.place_stone(Place(x, y), -1, value_table[0])
                        print("#1.5", actual[0], expected)
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
                        board.turn = 1
                        print("#1.6")
                        board.place_stone(Place(x, y), 1, value_table[1])
                        print("#1.7")
                        expected = board.debug_board_value(values) - value
                        print("#1.8", x, y)
                        board.place_stone(Place(x, y), -1, value_table[1])
                        print("#2", actual[1], expected)
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
            print("#3")
            if failure:
                print(board)
                print(board.str_values())
                return
            print("#4")
            value += board.getvalue(x, y)[board.turn]
            if board.turn == 0:
                board.place_stone(Place(x, y), 1, value_table[0])
            else:
                board.place_stone(Place(x, y), 1, value_table[1])
            print("#5")
