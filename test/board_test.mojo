from std.testing import assert_true
from std.random import seed, random_si64

from traits import Score
from board import Board, Place, first, second

comptime size = 19
comptime win_stones = 6
comptime values: List[Score] = [0, 1, 5, 25, 125, 625, 6240]


def test_place_stone() raises:
    seed(7)
    var board = Board[size, values, win_stones]()
    var value = Score(0)
    var n = 0
    for i in range(200):
        var turn = i % 2
        var xx = Int(random_si64(0, size - 1))
        var yy = Int(random_si64(0, size - 1))
        if board[xx, yy] == board.empty:
            for y in range(size):
                for x in range(size):
                    if board[x, y] == board.empty:
                        var actual = board.score(Place(x, y), first)
                        var b = board.copy()
                        b.place_stone(Place(x, y), first)
                        var expected = b.board_value(materialize[values]()) - value
                        if actual != expected and actual < 5000:
                            print(Place(x, y), "actual:", actual, "expected:", expected, "n", n)
                            print(board)
                            print(board.str_scores())
                            assert_true(False)
                        actual = board.score(Place(x, y), second)
                        b = board.copy()
                        b.place_stone(Place(x, y), second)
                        expected = value - b.board_value(materialize[values]())
                        if actual != expected and actual < 5000:
                            print(Place(x, y), "actual:", actual, "expected:", expected, "n", n)
                            print(board)
                            print(board.str_scores())
                            assert_true(False)
            if turn == first:
                value += board.score(Place(xx, yy), turn)
            else:
                value -= board.score(Place(xx, yy), turn)
            board.place_stone(Place(xx, yy), turn)
            n += 1


def main() raises:
    test_place_stone()
