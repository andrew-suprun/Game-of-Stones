from std.testing import assert_true
from std.random import seed, random_si64

from score import Score, Win
from board import Board, Place, Value, PlaceValue, first, second

comptime size = 19
comptime win_stones = 6
comptime values: List[Value] = [0, 1, 5, 25, 125, 625]


def test_places() raises:
    var board = Board[size, values, win_stones]()
    board.place_stone("j10", 0)
    board.place_stone("i10", 1)
    board.place_stone("i9", 1)
    print(board)
    print(board.str_values())

    var heap = List[PlaceValue](capacity=20)
    board.places(1, heap)
    print(len(heap))
    for move in heap:
        print(move)


def test_place_stone() raises:
    seed(7)
    var board = Board[size, values, win_stones]()
    var value = Value(0)
    var n = 0
    for i in range(200):
        var turn = i % 2
        var xx = Int(random_si64(0, size - 1))
        var yy = Int(random_si64(0, size - 1))
        if board[xx, yy] == board.empty:
            for y in range(size):
                for x in range(size):
                    if board[x, y] == board.empty:
                        var actual = board.value(Place(x, y), first)
                        var b = board.copy()
                        b.place_stone(Place(x, y), first)
                        var expected = b.debug_board_value(materialize[values]()) - value
                        if actual != expected and actual != Value.MAX:
                            print(Place(x, y), "actual:", actual, "expected:", expected, "n", n)
                            print(board)
                            print(board.str_values())
                            assert_true(False)
                        actual = board.value(Place(x, y), second)
                        b = board.copy()
                        b.place_stone(Place(x, y), second)
                        expected = value - b.debug_board_value(materialize[values]())
                        if actual != expected and actual != Value.MAX:
                            print(Place(x, y), "actual:", actual, "expected:", expected, "n", n)
                            print(board)
                            print(board.str_values())
                            assert_true(False)
            if turn == first:
                value += board.value(Place(xx, yy), turn)
            else:
                value -= board.value(Place(xx, yy), turn)
            board.place_stone(Place(xx, yy), turn)
            n += 1


def main() raises:
    test_places()
    test_place_stone()
