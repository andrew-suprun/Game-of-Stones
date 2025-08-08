from sys import env_get_int
from time import perf_counter_ns
import random

from tree import TTree
from game import Score, Decision, undecided, first_wins, second_wins
from board import Place, first

fn run[T1: TTree, T2: TTree](name1: String, name2: String) raises:
    var stats = Dict[String, Int]()
    stats[name1] = 0
    stats[name2] = 0
    stats["draw"] = 0
    with open("sim-connect6.log", "w") as log_file:
        for i in range(1, 11):
            random.seed(perf_counter_ns())
            var opening = opening_moves()
            print("\nopening ", i, ": ", sep="", end="")
            for move in opening:
                print(move, "", end="")
            print("\nblack:", name1, "white:", name2, end="")
            print()

            var decision = play_opening[T1, T2](2000, 2000, opening, log_file)
            if decision == first_wins:
                stats[name1] += 1
            elif decision == second_wins:
                stats[name2] += 1
            else:
                stats["draw"] += 1

            for stat in stats.items():
                print(stat.key, stat.value)

            print("\nblack:", name2, "white:", name1)
            decision = play_opening[T2, T1](2000, 2000, opening, log_file)
            if decision == first_wins:
                stats[name2] += 1
            elif decision == second_wins:
                stats[name1] += 1
            else:
                stats["draw"] += 1

            for stat in stats.items():
                print(stat.key, stat.value)

alias black = True
alias white = False

fn play_opening[T1: TTree, T2: TTree](time1: Int, time2: Int, opening: List[String], log: FileHandle) raises -> Decision:
    var g1 = T1.Game()
    var g2 = T2.Game()
    var t1 = T1(Score(0))
    var t2 = T2(Score(0))
    var turn = first

    for move in opening:
        g1.play_move(T1.Game.Move(move))
        g2.play_move(T2.Game.Move(move))
        print(move, file=log)
    print(g1, file=log)

    while True:
        var move: String        
        if turn == first:
            var (score, pv) = t1.search(g1, time1)
            debug_assert(len(pv) > 0)
            move = String(pv[0])
            print("move", move, score, end="")
            print(" pv:", end="")
            for move in pv:
                print("", move, end="")
            print()
        else:
            var (score, pv) = t2.search(g2, time2)
            debug_assert(len(pv) > 0)
            move = String(pv[0])
            print("move", move, score, end="")
            print(" pv:", end="")
            for move in pv:
                print("", move, end="")
            print()
        g1.play_move(T1.Game.Move(move))
        g2.play_move(T2.Game.Move(move))
        t1 = T1(Score(0))
        t2 = T2(Score(0))
        turn = 1 - turn

        var decision = g1.decision()
        if decision != undecided:
            return decision

fn opening_moves() -> List[String]:
    var places = List[Place]()
    for j in range(7, 12):
        for i in range(7, 12):
            if i != 9 or j != 9:
                places.append(Place(Int8(i), Int8(j)))
    random.shuffle(places)

    moves = List("j10")
    moves.append(String(places[0]) + "-" + String(places[1]))
    moves.append(String(places[2]) + "-" + String(places[3]))
    moves.append(String(places[4]) + "-" + String(places[5]))
    return moves
