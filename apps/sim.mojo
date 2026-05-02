from std.random import seed, shuffle
from std.time import perf_counter_ns
from std.reflection import reflect

from score import Score
from traits import TTree
from board import Place, first
from gomoku import Gomoku
from connect6 import Connect6
from mcts import Mcts

from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax

comptime Game1 = Gomoku[size=19, max_places=16, max_plies=100]
comptime Game2 = Gomoku[size=19, max_places=20, max_plies=100]

# comptime Game1 = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]
# comptime Game2 = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]

# comptime Tree1 = AlphaBetaNegamax[Game1]
# comptime Tree1 = PrincipalVariationNegamax[Game1]
comptime Tree1 = Mcts[Game1, 0.7]

# comptime Tree2 = AlphaBetaNegamax[Game2]
# comptime Tree2 = PrincipalVariationNegamax[Game2]
comptime Tree2 = Mcts[Game2, 0.7]


comptime seed_value = 6

comptime black = True
comptime white = False


def main() raises:
    run[Tree1, Tree2]("p16", 500, "p20", 500, openings())


def run[
    T1: TTree, T2: TTree
](name1: String, time1: UInt, name2: String, time2: UInt, openings: List[List[String]]) raises:
    print(t"Game: {reflect[T1.Game]().base_name()}: {name1}-{time1} vs. {name2}-{time2} seed: {seed_value}")

    var first_wins = 0
    var second_wins = 0
    var n = 1
    for opening in openings:
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

        print(t"result {n}: {name1}: {first_wins} - {name2}: {second_wins} ({n - first_wins - second_wins})")
        n += 1


def sim_opening[
    T1: TTree, T2: TTree
](name1: String, time1: UInt, name2: String, time2: UInt, opening: List[String]) raises -> String:
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
            var pv = t1.search(g1, time1)
            assert len(pv) > 0, t"{reflect[T1]().base_name()}.search() returned no results"
            move = String(pv[0])
            print(
                String(plies).ascii_rjust(4),
                ": ",
                name1.ascii_ljust(name_size),
                String(pv[0]).ascii_ljust(8),
                String(pv[0].score()).ascii_rjust(8),
                "  ",
                String(Float64((perf_counter_ns() - start) / 1_000_000) / 1000).ascii_ljust(7),
                sep="",
                end="",
            )
            for move in pv[1:]:
                print(t" {move}", end="")
            print()
            if len(pv) == 1 and pv[0].score().is_decisive():
                return name1 if pv[0].score() > 0 else name2 if pv[0].score() < 0 else "draw"
        else:
            var pv = t2.search(g2, time2)
            assert len(pv) > 0, t"{reflect[T2]().base_name()}.search() returned no results"
            move = String(pv[0])
            print(
                String(plies).ascii_rjust(4),
                ": ",
                name2.ascii_ljust(name_size),
                String(pv[0]).ascii_ljust(8),
                String(pv[0].score()).ascii_rjust(8),
                "  ",
                String(Float64((perf_counter_ns() - start) / 1_000_000) / 1000).ascii_ljust(7),
                sep="",
                end="",
            )
            for move in pv[1:]:
                print(t" {move}", end="")
            print()
            if len(pv) == 1 and pv[0].score().is_decisive():
                return name2 if pv[0].score() > 0 else name1 if pv[0].score() < 0 else "draw"
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
    for j in range(Game1.size / 2 - 2, Game1.size / 2 + 3):
        for i in range(Game1.size / 2 - 2, Game1.size / 2 + 3):
            if i != Game1.size / 2 or j != Game1.size / 2:
                places.append(String(Place(i, j)))
    for _ in range(100):
        shuffle(places)
        moves = [String(Place(Game1.size / 2, Game1.size / 2))]
        if reflect[Game1]().base_name() == "Connect6":
            for i in range(0, 3):
                moves.append(String(t"{places[i]}-{places[i+3]}"))
        else:
            for i in range(0, 5):
                moves.append(places[i])
        result.append(moves^)
    return result^
