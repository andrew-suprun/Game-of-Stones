from testing import assert_true
from random import seed, random_si64

from scores import Score
from board import Board
from game import Place
from connect6 import max_stones, value_table, values


def test_place_stone():
    seed(0)
    var board = Board[19, max_stones]()
    var value = Score(0)
    for _ in range(200):
        board.turn = Int(random_si64(0, 1))
        var x = Int(random_si64(0, board.size - 1))
        var y = Int(random_si64(0, board.size - 1))
        if board[x, y] == board.empty:
            var failure = False
            for y in range(board.size):
                for x in range(board.size):
                    if board[x, y] == board.empty:
                        var actual = board.getscores(Place(x, y))
                        board.turn = 0
                        board.place_stone(Place(x, y), 1, value_table[0])
                        var expected = board.debug_board_value(values) - value
                        board.place_stone(Place(x, y), -1, value_table[0])
                        if actual[0] != expected:
                            failure = True
                        board.turn = 1
                        board.place_stone(Place(x, y), 1, value_table[1])
                        expected = board.debug_board_value(values) - value
                        board.place_stone(Place(x, y), -1, value_table[1])
                        if actual[1] != expected:
                            failure = True
            if failure:
                print(board)
                print(board.str_scores())
                return
            value += board.getscores(Place(x, y))[board.turn]
            if board.turn == 0:
                board.place_stone(Place(x, y), 1, value_table[0])
            else:
                board.place_stone(Place(x, y), 1, value_table[1])


def test_top_moves():
    var board = Board[19, max_stones]()
    board.place_stone(Place(9, 9), 1, value_table[0])
    board.place_stone(Place(8, 9), 1, value_table[0])
    board.select_top_places()
    for i in range(1, 30):
        var parent = board.top_places[(i - 1) / 2]
        var child = board.top_places[i]
        assert_true(board.getscores(parent)[0] <= board.getscores(child)[0])
