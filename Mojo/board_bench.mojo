from benchmark import benchmark, Unit

from scores import Score
from board import Board
from game import Place
from connect6 import value_table, max_stones


fn bench_update_row():
    var board = Board[19, max_stones, 8]()
    var values = value_table[0] if board.turn == 0 else value_table[1]
    for _ in range(1000):
        board.update_row(0, board.size + 1, 6, 1, values)


fn bench_place_stone():
    var board = Board[19, max_stones, 8]()
    var values = value_table[0] if board.turn == 0 else value_table[1]
    for _ in range(1000):
        board.place_stone(Place(9, 9), 1, values)


def main():
    print("bench_update_row ", benchmark.run[bench_update_row]().mean(Unit.ms))
    print("bench_place_stone", benchmark.run[bench_place_stone]().mean(Unit.ms))
