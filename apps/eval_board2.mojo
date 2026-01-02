from traits import Score
from board import Board, Place, first, second

comptime win_stones = 6
comptime values: List[Float32] = [0, 1, 5, 25, 125, 625, Float32.MAX]


fn main() raises:
    var board = Board[19, values, win_stones]()
    board.place_stone(Place(0, 0), 0)
    board.place_stone(Place(9, 9), 1)
    board.place_stone(Place(8, 9), 0)
    print(board.str_scores())
