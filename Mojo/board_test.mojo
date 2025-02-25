from board import Board
from game import Place
from connect6 import value_table, max_stones, values


def test_place_stone():
    var board = Board[19, max_stones]()
    var value = board.debug_board_value(values)
    print(value)
