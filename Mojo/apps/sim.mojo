from sys import argv, env_get_int
from time import perf_counter_ns
import random

from tree import Game, Move, Place
from tree.impl import Tree
from game_of_stones import Connect6

alias m1 = env_get_int["M1", 60]()
alias p1 = env_get_int["P1", 32]()
alias c1 = env_get_int["C1", 20]()
alias m2 = env_get_int["M2", 60]()
alias p2 = env_get_int["P2", 32]()
alias c2 = env_get_int["C2", 20]()

alias Game1 = Connect6[19, m1, p1]
alias Game2 = Connect6[19, m2, p2]
alias Tree1 = Tree[Game1, c1]
alias Tree2 = Tree[Game2, c2]

fn main() raises:
    random.seed()
    for _ in range(10):
        var seed = Int(random.random_si64(Int.MIN, Int.MAX))
        play_opening(seed, True)
        play_opening(seed, False)

alias black = True
alias white = False

fn play_opening(seed: Int, g1_black: Bool):
    var g1 = Game1()
    var g2 = Game2()
    var t1 = Tree1()
    var t2 = Tree2()
    var n1 = String.write(m1, "-", p1, "-", c1)
    var n2 = String.write(m2, "-", p2, "-", c2)

    if g1_black:
        print("Black", n1, "White", n2)
    else:
        print("Black", n2, "White", n1)

    var turn = g1_black
    random.seed(seed)
    var opening = opening_moves()
    for move in opening:
        g1.play_move(move[])
        g2.play_move(move[])
        print(move[])
    print(g1)

    while True:
        var sims = 0
        var move: Move
        var player: String
        var deadline = perf_counter_ns() + 1_000_000_000
        if turn == black:
            while perf_counter_ns() < deadline:
                if t1.expand(g1):
                    print("DONE")
                    break
                sims += 1
            move = t1.best_move()
            player = n1
        else:
            while perf_counter_ns() < deadline:
                if t2.expand(g2):
                    print("DONE")
                    break
                sims += 1
            move = t2.best_move()
            player = n2
        turn = not turn
        g1.play_move(move)
        g2.play_move(move)
        t1.reset(g1)
        t2.reset(g2)
        var decision = g1.decision()
        print(move, decision, sims, player)
        print(g1)
        if decision == "first-win":
            if g1_black:
                print(n1, "wins")
            else:
                print(n2, "wins")
            return
        elif decision == "second-win":
            if g1_black:
                print(n2, "wins")
            else:
                print(n1, "wins")
            return
        elif decision == "draw":
            print(n2, "draw")
            return



fn opening_moves(out moves: List[Move]):
    var places = List[Place]()
    for j in range(7, 12):
        for i in range(7, 12):
            if i != 9 or j != 9:
                places.append(Place(Int8(i), Int8(j)))
    random.shuffle(places)

    moves = List(Move(Place(9, 9), Place(9, 9)))
    moves.append(Move(places[0], places[1]))
    moves.append(Move(places[2], places[3]))
    moves.append(Move(places[4], places[5]))
