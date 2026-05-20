from std.time import perf_counter_ns

from game_of_stones import TGame, Win, Loss, value_str
from game_of_stones import AlphaBetaNode, PrincipalVariationNode
from game_of_stones import Gomoku, Connect6

comptime C6 = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]
comptime G = Gomoku[size=19, max_places=16, max_plies=100]


def bench_abs_tree[Game: TGame](max_depth: Int) raises:
    var game = Game()

    game.play_move(Game.Move("j10"))
    game.play_move(Game.Move("i9"))
    game.play_move(Game.Move("k11"))
    game.play_move(Game.Move("i10"))
    game.play_move(Game.Move("l8"))
    game.play_move(Game.Move("k9"))
    print(game)

    print(t"\nGame: {reflect[Game].base_name()}; Tree ABS")

    var root = AlphaBetaNode[Game]({}, Loss, 0)
    var start = perf_counter_ns()
    var deadline = start + UInt(60_000_000_000)
    for max_depth in range(1, max_depth + 1):
        root.search(game, Loss, Win, 0, max_depth, deadline)
        var time = Float64(perf_counter_ns() - start) / 1_000_000_000
        var pv = List[Game.Move]()
        root._pv(pv)
        print(t"depth {max_depth}: value: {value_str(-root.value)} | time {time} | pv {pv}")
        # print(repr(root))
        if perf_counter_ns() > deadline:
            return
    # root.sort()
    # print(repr(root))


def bench_pvs_tree[Game: TGame](max_depth: Int) raises:
    var game = Game()

    game.play_move(Game.Move("j10"))
    game.play_move(Game.Move("i9"))
    game.play_move(Game.Move("k11"))
    game.play_move(Game.Move("i10"))
    game.play_move(Game.Move("l8"))
    game.play_move(Game.Move("k9"))
    print(game)

    print(t"\nGame: {reflect[Game].base_name()}; Tree PVS")

    var root = PrincipalVariationNode[Game]({}, Loss, 0)
    var start = perf_counter_ns()
    var deadline = start + UInt(60_000_000_000)
    for max_depth in range(1, max_depth + 1):
        root.search(game, Loss, Win, 0, max_depth, deadline)
        var time = Float64(perf_counter_ns() - start) / 1_000_000_000
        var pv = List[Game.Move]()
        root._pv(pv)
        print(t"depth {max_depth}: value: {value_str(-root.value)} | time {time} | pv {pv}")
        # print(repr(root))
        if perf_counter_ns() > deadline:
            return
    # root.sort()
    # print(repr(root))


def main() raises:
    bench_abs_tree[G](13)
    bench_pvs_tree[G](13)
    bench_abs_tree[C6](10)
    bench_pvs_tree[C6](10)
