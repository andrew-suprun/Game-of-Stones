from time import perf_counter_ns

from tree import Move
from tree.impl import Tree
from game_of_stones.connect6 import Connect6


alias G1 = Connect6[19, 60, 32]
alias G2 = Connect6[19, 60, 32]
alias T1 = Tree[G1, 30]
alias T2 = Tree[G2, 20]

fn main() raises:
    var game1 = G1()
    var game2 = G2()
    var tree1 = T1()
    var tree2 = T2()

    game1.play_move(Move("j10"))
    game2.play_move(Move("j10"))
    game1.play_move(Move("i9-i10"))
    game2.play_move(Move("i9-i10"))

    for _ in range(50):
        var deadline = perf_counter_ns() + 1_000_000_000
        var sims = 0
        while perf_counter_ns() < deadline:
            if tree1.expand(game1):
                print("DONE")
                break
            sims += 1
        var move = tree1.best_move()
        print("move", move, "sims", sims)
        game1.play_move(move)
        game2.play_move(move)
        tree1.reset(game1)
        tree2.reset(game2)
        var dec = game1.decision()
        print("decision", dec)
        if dec != "no-decision":
            break
        print(game1)

        deadline = perf_counter_ns() + 1_000_000_000
        sims = 0
        while perf_counter_ns() < deadline:
            if tree2.expand(game2):
                print("DONE")
                break
            sims += 1
        move = tree2.best_move()
        print("move", move, "sims", sims)
        game1.play_move(move)
        game2.play_move(move)
        tree1.reset(game1)
        tree2.reset(game2)
        dec = game1.decision()
        print("decision", dec)
        if dec != "no-decision":
            break
        print(game2)
    else:
        print("draw")

    print(game1)
