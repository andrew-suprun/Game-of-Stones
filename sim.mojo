from std.random import seed, shuffle
from std.time import perf_counter_ns

from game_of_stones import Debug
from game_of_stones import TTree, MoveValue, Place, first, is_decisive, value_str
from game_of_stones import Gomoku, Connect6
from game_of_stones import Mcts, AlphaBetaNegamax, PrincipalVariationNegamax
from game_of_stones.mcts2 import Mcts2

comptime seed_value = 8

comptime black = True
comptime white = False


# comptime Game = Gomoku[size=19, max_plies=100]
comptime Game = Connect6[size=19, max_plies=100]

# comptime T1 = AlphaBetaNegamax[Game]
# comptime T1 = PrincipalVariationNegamax[Game]
comptime T1 = Mcts[Game, 0.25]
comptime max_moves1 = 16
comptime time1: UInt = 200
comptime name1 = String(t"{reflect[T1].base_name()}-{max_moves1}-{time1}")

# comptime T2 = AlphaBetaNegamax[Game]
# comptime T2 = PrincipalVariationNegamax[Game]
comptime T2 = Mcts2[Game, 0.25]
comptime max_moves2 = 16
comptime time2: UInt = 200
comptime name2 = String(t"{reflect[T2].base_name()}-{max_moves2}-{time2}")


def main() raises:
    print(t"Game: {reflect[T1.Game].base_name()}: {reflect[T1].base_name()}-{max_moves1}-{time1} vs. {reflect[T2].base_name()}-{max_moves2}-{time2} seed: {seed_value}")

    var first_wins = 0
    var second_wins = 0
    var n = 1
    for opening in openings():
        print()
        print("------")
        print()
        print("opening ", n, ":", sep="", end="")
        for move in opening:
            print("", move, end="")
        print()
        print()
        var winner1 = sim_opening[T1, T2](name1, time1, name2, time2, opening)
        print()
        print("winner:", winner1)
        print()
        var winner2 = sim_opening[T2, T1](name2, time2, name1, time1, opening)
        print()
        print("winner:", winner2)
        print()

        var first = 0
        var second = 0
        if winner1 == name1:
            first += 1
        if winner1 == name2:
            second += 1
        if winner2 == name1:
            first += 1
        if winner2 == name2:
            second += 1
        if first > second:
            first_wins += 1
        if first < second:
            second_wins += 1

        print(t"result {n}: {name1} : {name2} - {first_wins} : {second_wins} ({first_wins - second_wins})")
        n += 1
    print(t"{reflect[T1.Game].base_name()}: {name1} : {name2} - {first_wins} : {second_wins} ({first_wins - second_wins})")


def sim_opening[T1: TTree, T2: TTree](name1: String, time1: UInt, name2: String, time2: UInt, opening: List[String]) raises -> String:
    if Debug:
        print(name1, "vs.", name2)
        print()

    var g1 = T1.Game()
    var g2 = T2.Game()
    var t1 = T1()
    var t2 = T2()
    var turn = first
    var plies = 1

    for move in opening:
        g1.play_move({move})
        g2.play_move({move})
        plies += 1

    while True:
        start = perf_counter_ns()
        var name_size = max(name1.byte_length(), name2.byte_length()) + 1
        var move: String
        if turn == first:
            var pv = t1.search(g1, max_moves1, time1)
            assert len(pv) > 0, t"{reflect[T1].base_name()}.search() returned no results"
            move = String(pv[0])
            print(
                String(plies).ascii_rjust(4),
                ": ",
                name1.ascii_ljust(name_size),
                String(pv[0]).ascii_ljust(8),
                String(value_str(-t1.value())).ascii_rjust(7),
                String((perf_counter_ns() - start) / 1_000_000).ascii_rjust(6),
                " ",
                sep="",
                end="",
            )
            for move in pv[1:]:
                print(t" {move}", end="")
            print()
            if len(pv) == 1 and is_decisive(t1.value()):
                return name1 if t1.value() < 0 else name2 if t1.value() > 0 else "draw"
        else:
            var pv = t2.search(g2, max_moves2, time2)
            assert len(pv) > 0, t"{reflect[T2].base_name()}.search() returned no results"
            move = String(pv[0])
            print(
                String(plies).ascii_rjust(4),
                ": ",
                name2.ascii_ljust(name_size),
                String(pv[0]).ascii_ljust(8),
                String(value_str(-t2.value())).ascii_rjust(7),
                String((perf_counter_ns() - start) / 1_000_000).ascii_rjust(6),
                " ",
                sep="",
                end="",
            )
            for move in pv[1:]:
                print(t" {move}", end="")
            print()
            if len(pv) == 1 and is_decisive(t2.value()):
                return name2 if t2.value() < 0 else name1 if t2.value() > 0 else "draw"
        g1.play_move({move})
        g2.play_move({move})
        plies += 1
        t1 = T1()
        t2 = T2()
        turn = 1 - turn


def openings() -> List[List[String]]:
    seed(seed_value)
    var result = List[List[String]]()
    var places = List[String]()
    for j in range(Game.size / 2 - 2, Game.size / 2 + 3):
        for i in range(Game.size / 2 - 2, Game.size / 2 + 3):
            if i != Game.size / 2 or j != Game.size / 2:
                places.append(String(Place(i, j)))
    for _ in range(100):
        shuffle(places)
        moves = [String(Place(Game.size / 2, Game.size / 2))]
        if reflect[Game].base_name() == "Connect6":
            for i in range(0, 4):
                moves.append(String(t"{places[i]}-{places[i+4]}"))
        else:
            for i in range(0, 6):
                moves.append(places[i])
        result.append(moves^)
    return result^
