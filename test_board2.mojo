from std.testing import assert_true
from std.random import seed, random_si64

from engine import Board, Place, Score, Value, PlaceValue, first, second

comptime size = 19
comptime win_stones = 6
comptime values: List[Value] = [0, 1, 11, 111, 1111, 11111]


def test_places() raises:
    var board = Board[size, values, win_stones]()
    board.place_stone("j10", 0)
    board.place_stone("i10", 1)
    board.place_stone("i9", 1)
    board.place_stone("i11", 0)
    board.place_stone("k9", 0)
    print(repr(board))


def main() raises:
    test_places()
