from testing import assert_true
from random import seed, random_si64

from tree import Score, Place
from game_of_stones.board import Board
from game_of_stones.connect6 import Connect6, max_stones, values


def test_place_stone():
    seed(0)
    var board = Board[values, 19, max_stones, 20]()
    var value = Score(0)
    for _ in range(200):
        var turn = Int(random_si64(0, 1))
        var x = Int(random_si64(0, board.size - 1))
        var y = Int(random_si64(0, board.size - 1))
        if board[x, y] == board.empty:
            var failure = False
            for y in range(board.size):
                for x in range(board.size):
                    if board[x, y] == board.empty:
                        var actual = board.getscores(Place(x, y))
                        turn = 0
                        board.place_stone(Place(x, y), turn)
                        var expected = board.board_value(values) - value
                        board.remove_stone()
                        if actual[0] != expected:
                            failure = True
                        turn = 1
                        board.place_stone(Place(x, y), turn)
                        expected = board.board_value(values) - value
                        board.remove_stone()
                        if actual[1] != expected:
                            failure = True
            if failure:
                print(board)
                print(board.str_scores())
                return
            value += board.getscores(Place(x, y))[turn]
            if turn == 0:
                board.place_stone(Place(x, y), turn)
            else:
                board.place_stone(Place(x, y), turn)


def test_top_moves():
    var board = Board[values, 19, max_stones, 20]()
    board.place_stone(Place(9, 9), 0)
    board.place_stone(Place(8, 9), 1)
    var top_places = List[Place]()
    board.top_places(0, top_places)
    for i in range(1, 20):
        var parent = top_places[(i - 1) / 2]
        var child = top_places[i]
        assert_true(board.getscores(parent)[0] <= board.getscores(child)[0])
