from benchmark import benchmark, Unit

from scores import Score
from board import Board, first
from game import Place
from connect6 import value_table, max_stones

fn bench_update_row():
    var board = Board[19, max_stones, 8]()
    var values = value_table[0] if board.turn == 0 else value_table[1]
    for _ in range(1000):
        board.update_row(0, board.size + 1, 6, values)

fn bench_place_stone():
    var board = Board[19, max_stones, 8]()
    var values = value_table[0]
    var score = Score(0)
    for _ in range(1000):
        board.place_stone(Place(9, 9), values)
        score += board.max_score[first]()
        board.remove_stone()

fn bench_max_score():
    var board = Board[19, max_stones, 8]()
    var score = Score(0)
    for _ in range(1000):
        score +=board.max_score[first]()

fn bench_top_places():
    var board = Board[19, max_stones, 20]()
    var top_places = List[Place]()
    for _ in range(1000):
        board.top_places(top_places)

def main():
    print("bench_update_row ", benchmark.run[bench_update_row]().mean(Unit.ms))
    print("bench_place_stone", benchmark.run[bench_place_stone]().mean(Unit.ms))
    print("bench_max_score  ", benchmark.run[bench_max_score]().mean(Unit.ms))
    print("bench_top_places ", benchmark.run[bench_top_places]().mean(Unit.ms))
