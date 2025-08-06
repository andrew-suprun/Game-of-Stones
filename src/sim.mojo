from sys import env_get_int
from time import perf_counter_ns
import random

from tree import TTree
from game import Score, Decision, undecided
from board import Place, first

fn run[T1: TTree, T2: TTree]() raises:
    with open("sim-connect6.log", "w") as log_file:
        for i in range(1, 11):
            random.seed(perf_counter_ns())
            var opening = opening_moves()
            print("\nopening ", i, ": ", sep="", end="")
            for move in opening:
                print(move, "", end="")
            print()
            var decision = play_opening[T1, T2](opening, log_file)
            print("decision", decision)
            decision = play_opening[T2, T1](opening, log_file)
            print("decision", decision)

alias black = True
alias white = False

fn play_opening[T1: TTree, T2: TTree](opening: List[String], log: FileHandle) raises -> Decision:
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
            var (score, pv) = t1.search(g1, 200)
            debug_assert(len(pv) > 0)
            move = String(pv[0])
            print("move", move, score)
        else:
            var (score, pv) = t2.search(g2, 200)
            debug_assert(len(pv) > 0)
            move = String(pv[0])
            print("move", move, score)
        g1.play_move(T1.Game.Move(move))
        g2.play_move(T2.Game.Move(move))
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

    moves = List(String("j10"))
    moves.append(String(places[0]) + "-" + String(places[1]))
    moves.append(String(places[2]) + "-" + String(places[3]))
    moves.append(String(places[3]) + "-" + String(places[5]))
    return moves
