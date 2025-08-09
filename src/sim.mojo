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
        for opening in openings:
            random.seed(perf_counter_ns())
            print("\nopening: ", end="")
            for move in opening:
                print(move, "", end="")
            print()

            print("\n", name1, "vs.", name2)
            var decision = play_opening[T1, T2](250, 250, opening, log_file)
            if decision == first_wins:
                stats[name1] += 1
            elif decision == second_wins:
                stats[name2] += 1
            else:
                stats["draw"] += 1

            for stat in stats.items():
                print(stat.key, stat.value)

            print("\n", name2, "vs.", name1)
            decision = play_opening[T2, T1](250, 250, opening, log_file)
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

alias openings: List[List[String]] = [
    ["j10",  "h10-h11",  "i11-k12", "i9-i10"],
    ["j10",  "h10-i8",  "j8-l10", "i9-k9"],
    ["j10",  "h10-j11",  "j9-k12", "i12-k9"],
    ["j10",  "h10-j9",  "i10-l11", "i11-k11"],
    ["j10",  "h10-k11",  "h9-l8", "i9-k10"],
    ["j10",  "h10-k9",  "h11-i12", "k12-l9"],
    ["j10",  "h10-l10",  "h9-k8", "j11-l8"],
    ["j10",  "h10-l10",  "h9-k9", "i8-l9"],
    ["j10",  "h10-l12",  "h12-k10", "k12-l11"],
    ["j10",  "h10-l8",  "h11-i10", "i9-j11"],
    ["j10",  "h11-i10",  "j11-k10", "i8-j9"],
    ["j10",  "h11-i8",  "l9-l10", "j9-k8"],
    ["j10",  "h11-j9",  "k8-l10", "h8-i11"],
    ["j10",  "h11-k12",  "l9-l12", "i11-l11"],
    ["j10",  "h11-k9",  "h10-j8", "i8-k10"],
    ["j10",  "h11-k9",  "l9-l11", "i12-k8"],
    ["j10",  "h11-l12",  "j9-l10", "h10-h12"],
    ["j10",  "h12-i8",  "j11-l9", "h10-i12"],
    ["j10",  "h12-j12",  "h11-l8", "i8-j9"],
    ["j10",  "h12-j9",  "h10-k9", "h11-i8"],
    ["j10",  "h12-j9",  "i12-k12", "i8-l10"],
    ["j10",  "h12-k10",  "h9-i12", "i8-j8"],
    ["j10",  "h12-l10",  "h10-k10", "h9-i9"],
    ["j10",  "h12-l10",  "i10-k12", "h9-i8"],
    ["j10",  "h12-l10",  "k9-k11", "j8-j11"],
    ["j10",  "h8-h12",  "j12-l9", "k12-l10"],
    ["j10",  "h8-i10",  "h10-l12", "h11-i11"],
    ["j10",  "h8-j9",  "k8-l12", "j11-k11"],
    ["j10",  "h8-k10",  "i12-l10", "j9-k9"],
    ["j10",  "h8-k8",  "h9-k12", "i11-k10"],
    ["j10",  "h8-k8",  "k12-l8", "i11-j8"],
    ["j10",  "h8-l11",  "i11-k11", "i10-j12"],
    ["j10",  "h8-l12",  "k12-l11", "h10-j8"],
    ["j10",  "h8-l9",  "i9-l11", "j12-k11"],
    ["j10",  "h9-h12",  "k8-l11", "k9-l8"],
    ["j10",  "h9-i10",  "h11-i12", "j12-l8"],
    ["j10",  "h9-i10",  "i11-k11", "h12-j8"],
    ["j10",  "h9-i8",  "j12-k11", "h8-h10"],
    ["j10",  "h9-j9",  "i11-l9", "i10-k11"],
    ["j10",  "h9-k11",  "h11-i11", "h10-k10"],
    ["j10",  "h9-k11",  "i10-j8", "j9-k9"],
    ["j10",  "h9-l11",  "j9-j12", "h10-i12"],
    ["j10",  "h9-l8",  "l9-l12", "i9-j11"],
    ["j10",  "i10-i11",  "h11-l12", "k8-l8"],
    ["j10",  "i10-i12",  "h9-k12", "j9-k11"],
    ["j10",  "i10-i12",  "j12-l11", "h9-k11"],
    ["j10",  "i10-j12",  "h9-i8", "h12-j9"],
    ["j10",  "i10-j8",  "h8-j9", "k11-l8"],
    ["j10",  "i10-k10",  "j9-k9", "j8-j12"],
    ["j10",  "i10-k9",  "h8-h11", "h10-k11"],
    ["j10",  "i10-l10",  "h9-l9", "i12-k9"],
    ["j10",  "i10-l10",  "k11-l11", "h12-k10"],
    ["j10",  "i10-l10",  "k11-l8", "i11-j11"],
    ["j10",  "i10-l12",  "i11-l11", "h12-l9"],
    ["j10",  "i10-l12",  "l10-l11", "h9-i12"],
    ["j10",  "i11-j11",  "h8-j9", "k8-l9"],
    ["j10",  "i11-k11",  "h11-l11", "i12-l12"],
    ["j10",  "i11-k11",  "h8-l8", "j9-k9"],
    ["j10",  "i11-k12",  "i10-k11", "k9-k10"],
    ["j10",  "i11-k8",  "i8-j8", "i10-l11"],
    ["j10",  "i11-k8",  "k10-l10", "h12-i12"],
    ["j10",  "i11-l8",  "h8-i10", "k12-l11"],
    ["j10",  "i11-l8",  "i8-l9", "h9-i10"],
    ["j10",  "i12-j11",  "i10-i11", "h11-j8"],
    ["j10",  "i12-j11",  "k10-l8", "h8-h9"],
    ["j10",  "i12-j12",  "i8-l10", "k9-l11"],
    ["j10",  "i12-j8",  "h8-l11", "h11-i10"],
    ["j10",  "i12-j8",  "i11-j12", "i9-k11"],
    ["j10",  "i12-l10",  "h10-k8", "i10-k9"],
    ["j10",  "i12-l11",  "h11-j9", "i10-l8"],
    ["j10",  "i12-l8",  "h10-l11", "i8-k12"],
    ["j10",  "i12-l9",  "i8-j12", "j8-k9"],
    ["j10",  "i8-i11",  "h10-l11", "j9-k12"],
    ["j10",  "i8-i9",  "h8-l10", "i11-k8"],
    ["j10",  "i8-i9",  "k9-l11", "j12-l10"],
    ["j10",  "i8-j8",  "j9-j12", "k10-l9"],
    ["j10",  "i8-j9",  "j11-j12", "h8-i12"],
    ["j10",  "i8-k11",  "k9-k10", "i11-j9"],
    ["j10",  "i8-k8",  "i11-j8", "j9-k11"],
    ["j10",  "i9-i10",  "h10-j11", "j9-k10"],
    ["j10",  "i9-i10",  "h8-l11", "h12-k9"],
    ["j10",  "i9-i10",  "j8-j9", "i11-j11"],
    ["j10",  "i9-i12",  "i11-k10", "k9-k11"],
    ["j10",  "i9-i12",  "j11-k10", "j9-l12"],
    ["j10",  "i9-j9",  "h8-k8", "h12-i8"],
    ["j10",  "i9-k8",  "i11-l9", "l10-l11"],
    ["j10",  "i9-l10",  "j8-k9", "i8-i11"],
    ["j10",  "i9-l11",  "j11-k11", "h11-l8"],
    ["j10",  "i9-l12",  "h10-k8", "h12-l9"],
    ["j10",  "i9-l12",  "i8-i11", "h10-j9"],
    ["j10",  "i9-l9",  "l8-l12", "k12-l11"],
    ["j10",  "j11-k10",  "h12-l11", "h10-j9"],
    ["j10",  "j11-k10",  "h12-l11", "i11-k8"],
    ["j10",  "j11-k11",  "h8-h12", "i11-l12"],
    ["j10",  "j11-k11",  "i12-l10", "h10-i10"],
    ["j10",  "j11-k8",  "i12-j12", "k11-l9"],
    ["j10",  "j11-k9",  "k12-l12", "h10-i9"],
    ["j10",  "j11-l10",  "k9-l9", "i12-l8"],
    ["j10",  "j11-l12",  "h12-k9", "i8-i9"],
    ["j10",  "j11-l9",  "h9-k11", "k9-k10"],
    ["j10",  "j12-k12",  "k8-l10", "h9-j8"],
    ["j10",  "j12-l10",  "h9-k11", "i11-i12"],
    ["j10",  "j12-l10",  "k11-l11", "i11-k12"],
    ["j10",  "j12-l12",  "h8-j8", "i8-j9"],
    ["j10",  "j8-j11",  "h10-l10", "k12-l9"],
    ["j10",  "j8-j9",  "i10-l11", "k8-k11"],
    ["j10",  "j8-k11",  "h10-l10", "j9-k10"],
    ["j10",  "j8-l11",  "h12-i12", "h10-j9"],
    ["j10",  "j9-k10",  "i8-l11", "h10-j12"],
    ["j10",  "j9-k12",  "i9-l9", "h11-j12"],
    ["j10",  "j9-k12",  "j12-k8", "i9-l10"],
    ["j10",  "j9-l10",  "h12-k11", "i12-j11"],
    ["j10",  "j9-l10",  "i8-l9", "k8-k9"],
    ["j10",  "j9-l11",  "h11-j12", "h10-k11"],
    ["j10",  "j9-l11",  "i8-k8", "h8-l10"],
    ["j10",  "j9-l9",  "h12-l11", "k8-k11"],
    ["j10",  "k10-k11",  "k8-k12", "j9-l11"],
    ["j10",  "k10-l12",  "i12-k12", "j12-l8"],
    ["j10",  "k10-l9",  "j12-l8", "j11-l12"],
    ["j10",  "k11-l11",  "i12-k9", "h10-i9"],
    ["j10",  "k11-l11",  "i8-l10", "k9-l12"],
    ["j10",  "k12-l10",  "k9-k10", "i9-k8"],
    ["j10",  "k12-l12",  "h11-k11", "i9-l10"],
    ["j10",  "k12-l9",  "h10-k8", "j8-k9"],
    ["j10",  "k8-k9",  "j8-l11", "h11-j9"],
    ["j10",  "k8-l12",  "j12-k10", "h10-i12"],
    ["j10",  "k8-l8",  "h10-l9", "i9-k10"],
    ["j10",  "k8-l9",  "h11-l8", "h8-h10"],
    ["j10",  "k9-k10",  "i8-l11", "j11-l8"],
    ["j10",  "k9-l10",  "k12-l9", "h10-h11"],
    ["j10",  "k9-l11",  "l10-l12", "k12-l9"],
    ["j10",  "k9-l8",  "i12-k10", "i10-i11"],
    ["j10",  "k9-l8",  "k11-l12", "i9-i11"],
    ["j10",  "l11-l12",  "h12-j12", "k8-l9"],
    ["j10",  "l8-l10",  "i12-l11", "i11-j8"],
    ["j10",  "l8-l10",  "i9-j12", "i11-j11"],
]
