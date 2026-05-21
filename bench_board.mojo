from std.benchmark import benchmark, Unit, keep, black_box

from engine import Board, Value, Place, PlaceValue, first

comptime win_stones = 6
comptime values: List[Value] = [0, 1, 5, 25, 125, 625]


def bench_max_value():
    var board = Board[19, values, win_stones]()
    for _ in range(1_000_000):
        keep(board.max_value(0))


def bench_copy():
    var board = Board[19, values, win_stones]()
    for _ in range(500_000):
        var b = board.copy()
        keep(b)
        board = b.copy()
        keep(board)


def bench_update_row():
    var board = Board[19, values, win_stones]()
    ref value_table = materialize[board.value_table]()
    ref values = value_table[0]
    for _ in range(40_000):
        var copy = board.copy()
        for y in range(5):
            for x in range(5):
                copy._update_row(y * 19 + x, 20, 6, values)
                keep(copy._values[0])


def bench_place_stone():
    var board = Board[19, values, win_stones]()
    board.place_stone(Place(9, 9), 0)
    board.place_stone(Place(8, 8), 1)
    board.place_stone(Place(8, 9), 0)
    var heap = List[PlaceValue](capacity=20)
    var places = List[Place](capacity=100)
    var copy = board.copy()
    for _ in range(50):
        heap.clear()
        copy.places(0, 20, heap)
        copy.place_stone(heap[0].place, 0)
        places.append(heap[0].place)
        heap.clear()
        copy.places(1, 20, heap)
        copy.place_stone(heap[0].place, 1)
        places.append(heap[0].place)

    for _ in range(10_000):
        var copy = board.copy()
        for i in range(50):
            copy.place_stone(places[2 * i], 0)
            copy.place_stone(places[2 * i + 1], 1)
            keep(copy)


def bench_rollout():
    var board = Board[19, values, win_stones]()
    board.place_stone(Place(9, 9), 0)
    board.place_stone(Place(8, 8), 1)
    board.place_stone(Place(8, 9), 0)
    var places = List[PlaceValue](capacity=20)
    for _ in range(10_000):
        var copy = board.copy()
        for _ in range(50):
            places.clear()
            copy.places(0, 20, places)
            copy.place_stone(places[0].place, 0)
            places.clear()
            copy.places(1, 20, places)
            copy.place_stone(places[0].place, 1)
        keep(copy)


def bench_places():
    var board = Board[19, values, win_stones]()
    var places = List[PlaceValue](capacity=20)
    for _ in range(1_000_000):
        places.clear()
        board.places(first, 20, places)
        keep(places)


def bench[f: def() thin](name: String, unit: String) raises:
    var report = benchmark.run[func2=f](0, 1, 3, 6)
    print(t"{name} {round(report.mean(Unit.s), 3)} {unit}")


def main() raises:
    print("--- board ---")
    bench[bench_max_value]("max_score  ", "sec/1M")
    bench[bench_copy]("copy       ", "sec/1M")
    bench[bench_update_row]("update_row ", "sec/1M")
    bench[bench_place_stone]("place_stone", "sec/1M")
    bench[bench_rollout]("rollout    ", "sec/1M")
    bench[bench_places]("places     ", "sec/1M")
