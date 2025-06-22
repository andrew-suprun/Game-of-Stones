from benchmark import benchmark, Unit, keep

from score import Score
from board import Board, Place, first, _value_table

alias max_stones = 6
alias values = List[Score](0, 1, 5, 25, 125, 625)

fn bench_update_row():
    var board = Board[values, 19, max_stones, 8]()
    var vv = _value_table[6, values]()
    for _ in range(1000):
        board._update_row(0, board.size + 1, 6, vv[0])
    keep(board.scores[5*20])

fn bench_place_stone():
    var board = Board[values, 19, max_stones, 8]()
    var score = Score(0)
    for _ in range(1000):
        var new_board = board
        new_board.place_stone(Place(9, 9), 0)
        score += new_board.score
    keep(score)

fn bench_top_places():
    var board = Board[values, 19, max_stones, 20]()
    var top_places = List[Place]()
    for _ in range(1000):
        board.top_places(first, top_places)

fn main() raises:
    print("\n--- board (ms/1000) ---")
    print("update_row ", benchmark.run[bench_update_row]().mean(Unit.ms))
    print("place_stone", benchmark.run[bench_place_stone]().mean(Unit.ms))
    print("top_places ", benchmark.run[bench_top_places]().mean(Unit.ms))
