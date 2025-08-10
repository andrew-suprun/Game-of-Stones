
from tree import TTree
from game import Score, Decision, undecided, first_wins, second_wins
from board import first

alias timeout = 200

fn run[T1: TTree, T2: TTree](name1: String, name2: String, openings: List[List[String]]) raises:
    var stats = Dict[String, Int]()
    stats[name1] = 0
    stats[name2] = 0
    stats["draw"] = 0
    for opening in openings:
        print()
        print("opening:", end="")
        for move in opening:
            print("", move, end="")
        print()

        print()
        print(name1, "vs.", name2)
        print()
        var decision = play_opening[T1, T2](timeout, timeout, opening)
        if decision == first_wins:
            stats[name1] += 1
        elif decision == second_wins:
            stats[name2] += 1
        else:
            stats["draw"] += 1

        print()
        for stat in stats.items():
            print(stat.key, stat.value)

        print()
        print(name2, "vs.", name1)
        print()
        decision = play_opening[T2, T1](timeout, timeout, opening)
        if decision == first_wins:
            stats[name2] += 1
        elif decision == second_wins:
            stats[name1] += 1
        else:
            stats["draw"] += 1
        print()
        for stat in stats.items():
            print(stat.key, stat.value)

alias black = True
alias white = False

fn play_opening[T1: TTree, T2: TTree](time1: Int, time2: Int, opening: List[String]) raises -> Decision:
    var g1 = T1.Game()
    var g2 = T2.Game()
    var t1 = T1(Score(0))
    var t2 = T2(Score(0))
    var turn = first

    for move in opening:
        g1.play_move(T1.Game.Move(move))
        g2.play_move(T2.Game.Move(move))

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

