from std.benchmark import benchmark, Unit, keep, black_box

from engine import Board, Place, Stone

comptime size = 19
comptime win_stones = 6


# def bench_max_value():
#     var board = Board[19, values, win_stones]()
#     for _ in range(1_000_000):
#         keep(board.max_value(0))


# def bench_copy():
#     var board = Board[19, values, win_stones]()
#     for _ in range(500_000):
#         var b = board.copy()
#         keep(b)
#         board = b.copy()
#         keep(board)


# def bench_update_row():
#     var board = Board[19, values, win_stones]()
#     ref value_table = materialize[board.value_table]()
#     ref values = value_table[0]
#     for _ in range(40_000):
#         var copy = board.copy()
#         for y in range(5):
#             for x in range(5):
#                 copy._update_row(y * 19 + x, 20, 6, values)
#                 keep(copy._values[0])


def bench_place_stone():
    var board = Board[size, win_stones]()
    for _ in range(1_000_000):
        board.place_stone(black_box(Place(9, 9)), Stone.black)


# def bench_rollout():
#     var board = Board[19, values, win_stones]()
#     board.place_stone(Place(9, 9), 0)
#     board.place_stone(Place(8, 8), 1)
#     board.place_stone(Place(8, 9), 0)
#     var places = List[PlaceValue](capacity=20)
#     for _ in range(10_000):
#         var copy = board.copy()
#         for _ in range(50):
#             places.clear()
#             copy.places(0, places)
#             copy.place_stone(places[0].place, 0)
#             places.clear()
#             copy.places(1, places)
#             copy.place_stone(places[0].place, 1)
#         keep(copy)


# def bench_places():
#     var board = Board[19, values, win_stones]()
#     var places = List[PlaceValue](capacity=20)
#     for _ in range(1_000_000):
#         places.clear()
#         board.places(first, places)
#         keep(places)


def bench[f: def() thin](name: String, unit: String) raises:
    var report = benchmark.run[func2=f](0, 1, 3, 6)
    print(t"{name} {round(report.mean(Unit.s), 3)} {unit}")


def main() raises:
    print("--- board ---")
    # bench[bench_max_value]("max_score  ", "sec/1M")
    # bench[bench_copy]("copy       ", "sec/1M")
    # bench[bench_update_row]("update_row ", "sec/1M")
    bench[bench_place_stone]("place_stone", "sec/1M")
    # bench[bench_rollout]("rollout    ", "sec/1M")
    # bench[bench_places]("places     ", "sec/1M")
