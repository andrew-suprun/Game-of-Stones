from benchmark import benchmark, Unit

from scores import Score
from board import Board, first
from game import Place
from connect6 import values, max_stones
import values as v

fn bench_update_row():
    var board = Board[values, 19, max_stones, 8]()
    var vv = v.value_table[6, values]()
    for _ in range(1000):
        board.update_row(first, board.size + 1, 6, vv[0])

fn bench_place_stone():
    var board = Board[values, 19, max_stones, 8]()
    var score = Score(0)
    for _ in range(1000):
        board.place_stone(Place(9, 9), 0)
        score += board.max_score(first)
        board.remove_stone()

fn bench_max_score():
    var board = Board[values, 19, max_stones, 8]()
    var score = Score(0)
    for _ in range(1000):
        score +=board.max_score(first)

fn bench_top_places():
    var board = Board[values, 19, max_stones, 20]()
    var top_places = List[Place]()
    for _ in range(1000):
        board.top_places(first, top_places)

fn main() raises:
    print("bench_update_row ", benchmark.run[bench_update_row]().mean(Unit.ms))
    print("bench_place_stone", benchmark.run[bench_place_stone]().mean(Unit.ms))
    print("bench_max_score  ", benchmark.run[bench_max_score]().mean(Unit.ms))
    print("bench_top_places ", benchmark.run[bench_top_places]().mean(Unit.ms))
