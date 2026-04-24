from std.benchmark import benchmark, Unit, keep, black_box

from traits import Score
from board import Board, Place, PlaceScore, first

comptime win_stones = 6
comptime values: List[Score] = [0, 1, 5, 25, 125, 625, 6250]


def bench_max_score():
    var board = Board[19, values, win_stones]()
    for _ in range(1000):
        keep(board.max_score(0))


def bench_max_simd_int16():
    var simd: SIMD[DType.int16, 361] = 1
    var data = black_box(simd)
    for _ in range(1000):
        keep(data.reduce_max())


def bench_max_simd_int32():
    var simd: SIMD[DType.int32, 361] = 1
    var data = black_box(simd)
    for _ in range(1000):
        keep(data.reduce_max())


def bench_max_simd_float32():
    var simd: SIMD[DType.float32, 361] = 1
    var data = black_box(simd)
    for _ in range(1000):
        keep(data.reduce_max())


def bench_copy():
    var board = Board[19, values, win_stones]()
    for _ in range(500):
        var b = board.copy()
        keep(b)
        board = b.copy()
        keep(board)


def bench_update_row():
    var board = Board[19, values, win_stones]()
    ref value_table = materialize[board.value_table]()
    ref scores = value_table[0]
    for _ in range(1000):
        board._update_row(0, 20, 6, scores)
    keep(board._scores[5 * 20])


def bench_place_stone():
    var board = Board[19, values, win_stones]()
    var score = Score(0)
    var b = board.copy()
    for _ in range(1000):
        b.place_stone(Place(9, 9), 0)
        score += board._score
    keep(score)


def bench_places():
    var board = Board[19, values, win_stones]()
    var places = List[PlaceScore](capacity=20)
    for _ in range(1000):
        places.clear()
        _ = board.places(first, places)


def main() raises:
    print("--- board ---")
    print("max_score  ", benchmark.run[func2=bench_max_score](0, 1, 3, 6).mean(Unit.ms))
    print("max_int16  ", benchmark.run[func2=bench_max_simd_int16](0, 1, 3, 6).mean(Unit.ms))
    print("max_int32  ", benchmark.run[func2=bench_max_simd_int32](0, 1, 3, 6).mean(Unit.ms))
    print("max_float3 ", benchmark.run[func2=bench_max_simd_float32](0, 1, 3, 6).mean(Unit.ms))
    print("copy       ", benchmark.run[func2=bench_copy](0, 1, 3, 6).mean(Unit.ms))
    print("update_row ", benchmark.run[func2=bench_update_row](0, 1, 3, 6).mean(Unit.ms))
    print("place_stone", benchmark.run[func2=bench_place_stone](0, 1, 3, 6).mean(Unit.ms))
    print("places     ", benchmark.run[func2=bench_places](0, 1, 3, 6).mean(Unit.ms))
