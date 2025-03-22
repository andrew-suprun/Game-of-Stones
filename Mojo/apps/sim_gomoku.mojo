from sys import argv, env_get_int
from time import perf_counter_ns
import random

from tree import Game, Move, Place, Score
from tree.tree import Tree
from game_of_stones import Gomoku

alias m1 = env_get_int["M1", 20]()
alias c1 = env_get_int["C1", 40]()
alias m2 = env_get_int["M2", 20]()
alias c2 = env_get_int["C2", 40]()

alias Game1 = Gomoku[19, m1]
alias Game2 = Gomoku[19, m2]
alias Tree1 = Tree[Game1, c1]
alias Tree2 = Tree[Game2, c2]

var first_wins = 0
var second_wins = 0
var draws = 0

fn main() raises:
    var n1 = String.write(m1,  "-", c1)
    var n2 = String.write(m2,  "-", c2)
    print(n1, "vs.", n2)
    with open("log-gomoku.log", "w") as log_file:
        for i in range(1, 11):
            random.seed(perf_counter_ns())
            var opening = opening_moves()
            print("\nopening ", i, ": ", sep="", end="")
            for move in opening:
                print(move[], "", end="")
            print()
            play_opening(opening, True, log_file)
            play_opening(opening, False, log_file)

alias black = True
alias white = False

fn play_opening(opening: List[Move], g1_black: Bool, log: FileHandle):
    var g1 = Game1()
    var g2 = Game2()
    var t1 = Tree1()
    var t2 = Tree2()
    var n1 = String.write(m1, "-", c1)
    var n2 = String.write(m2, "-", c2)

    if g1_black:
        print("Black", n1, "White", n2, file=log)
    else:
        print("Black", n2, "White", n1, file=log)

    var turn = g1_black
    for move in opening:
        g1.play_move(move[])
        g2.play_move(move[])
        print(move[], file=log)
    print(g1, file=log)

    while True:
        var sims = 0
        var move: Move
        var player: String
        var value: Score
        var forced = False
        var deadline = perf_counter_ns() + 200_000_000
        if turn == black:
            while perf_counter_ns() < deadline:
                if t1.expand(g1):
                    forced = True
                    break
                sims += 1
            move = t1.best_move()
            value = t1.value()
            player = n1
        else:
            while perf_counter_ns() < deadline:
                if t2.expand(g2):
                    forced = True
                    break
                sims += 1
            move = t2.best_move()
            value = t2.value()
            player = n2
        turn = not turn
        g1.play_move(move)
        g2.play_move(move)
        t1.reset(g1)
        t2.reset(g2)
        var decision = g1.decision()
        print("move", move, decision, sims, player, value, forced, file=log)
        print(g1, file=log)
        if decision == "first-win":
            if g1_black:
                print(n1, "wins", file=log)
                first_wins += 1
            else:
                print(n2, "wins", file=log)
                second_wins += 1
            break
        elif decision == "second-win":
            if g1_black:
                print(n2, "wins", file=log)
                second_wins += 1
            else:
                print(n1, "wins", file=log)
                first_wins += 1
            break
        elif decision == "draw":
            print(n2, "draw", file=log)
            draws += 1
            break
    print(first_wins, ":", second_wins, " (", draws, ")", sep="")


fn opening_moves(out moves: List[Move]):
    var places = List[Place]()
    for j in range(7, 12):
        for i in range(7, 12):
            if i != 9 or j != 9:
                places.append(Place(Int8(i), Int8(j)))
    random.shuffle(places)

    moves = List(Move(Place(9, 9), Place(9, 9)))
    moves.append(Move(places[0], places[0]))
    moves.append(Move(places[1], places[1]))
    moves.append(Move(places[2], places[2]))
    moves.append(Move(places[3], places[3]))
    moves.append(Move(places[4], places[4]))
