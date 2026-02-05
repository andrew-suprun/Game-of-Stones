from benchmark import benchmark, Unit, keep

from traits import Score
from board import Board, Place, first

comptime win_stones = 6
comptime values: List[Float32] = [0, 1, 5, 25, 125, 625]


fn bench_update_row():
    var board = Board[values, 19, win_stones]()
    for _ in range(1000):
        board._update_row(0, 0, 20, 6)
    keep(board._scores[5 * 20])


fn bench_place_stone():
    var board = Board[values, 19, win_stones]()
    var score = Score(0)
    for _ in range(1000):
        board.place_stone(Place(9, 9), 0)
        score += board._score
        board.remove_stone()
    keep(score.value)


fn bench_places():
    var board = Board[values, 19, win_stones]()
    var places = List[Place](capacity=20)
    for _ in range(1000):
        places.clear()
        _ = board.places(first, places)


fn main() raises:
    print("--- board ---")
    print("update_row ", benchmark.run[func2=bench_update_row](0, 1, 3, 6).mean(Unit.ms))
    print("place_stone", benchmark.run[func2=bench_place_stone](0, 1, 3, 6).mean(Unit.ms))
    print("places     ", benchmark.run[func2=bench_places](0, 1, 3, 6).mean(Unit.ms))
