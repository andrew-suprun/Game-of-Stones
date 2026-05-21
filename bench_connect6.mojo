from std.benchmark import benchmark, Unit, keep

from game_of_stones import Connect6, MoveValue

comptime C6 = Connect6[size=19, max_plies=100]


def bench_moves():
    var game = C6()
    try:
        game.play_move("j10")
        game.play_move("i9-i10")
    except:
        pass
    var moves = List[MoveValue[C6.Move]](capacity=20)
    for _ in range(1000):
        game.top_moves(20, moves)
        keep(moves[0].value)


def main() raises:
    print("--- connect6 ---")
    print("moves", round(benchmark.run[func2=bench_moves](0, 1, 3, 6).mean(Unit.ms), 3), "msec/1K")
