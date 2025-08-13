from benchmark import benchmark, Unit, keep

from game import Score
from board import Board, Place, size, first, _value_table

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625)


fn bench_update_row():
    var board = Board[values, win_stones]()
    var vv = _value_table[6, values]()
    for _ in range(1000):
        board._update_row(0, size + 1, 6, vv[0])
    keep(board._scores[5 * 20])


fn bench_place_stone():
    var board = Board[values, win_stones]()
    var score = Score(0)
    for _ in range(1000):
        var new_board = board
        new_board.place_stone(Place(9, 9), 0)
        new_board.place_stone(Place(8, 8), 0)
        score += new_board._score


fn bench_places():
    var board = Board[values, win_stones]()
    for _ in range(1000):
        _ = board.places(first, 20)


fn main() raises:
    print("--- board (ms/1000) ---")
    print("update_row ", benchmark.run[bench_update_row]().mean(Unit.ms))
    print("place_stone", benchmark.run[bench_place_stone]().mean(Unit.ms))
    print("places     ", benchmark.run[bench_places]().mean(Unit.ms))
