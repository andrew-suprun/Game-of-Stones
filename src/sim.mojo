from time import perf_counter_ns

from traits import TTree
from score import Score
from board import first

comptime black = True
comptime white = False


fn run[T1: TTree, T2: TTree](name1: String, time1: UInt, name2: String, time2: UInt, openings: List[List[String]]) raises:
    print(name1, "-", time1, " vs. ", name2, "-", time2, sep="")

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

        print("result: ", name1, ": ", first_wins, " - ", name2, ": ", second_wins, sep="")

        n += 1


fn sim_opening[T1: TTree, T2: TTree](name1: String, time1: UInt, name2: String, time2: UInt, opening: List[String]) raises -> String:
    # print()
    # print(name1, "vs.", name2)
    # print()

    var g1 = T1.Game()
    var g2 = T2.Game()
    var t1 = T1()
    var t2 = T2()
    var turn = first
    var plies = 0

    for move in opening:
        _ = g1.play_move(T1.Game.Move(move))
        _ = g2.play_move(T2.Game.Move(move))
        plies += 1

    # print("opening:", end="")
    # for move in opening:
    #     print("", move, end="")
    # # print(g1)
    # print()

    while True:
        start = perf_counter_ns()
        var name_size = max(len(name1), len(name2)) + 1
        var move: String
        if turn == first:
            var result = t1.search(g1, time1)
            move = String(result.move)
            score = result.score
            print("  ", rpad(name1, name_size), rpad(String(result.move), 8), lpad(String(result.score), 7), "  ", (perf_counter_ns() - start) / 1_000_000_000, "s", sep="")
        else:
            var result = t2.search(g2, time2)
            move = String(result.move)
            score = -result.score
            print("  ", rpad(name2, name_size), rpad(String(result.move), 8), lpad(String(result.score), 7), "  ", (perf_counter_ns() - start) / 1_000_000_000, "s", sep="")
        var score = g1.play_move(T1.Game.Move(move))
        _ = g2.play_move(T2.Game.Move(move))
        # print(g1)
        plies += 1
        t1 = T1()
        t2 = T2()
        turn = 1 - turn

        if score.is_decisive():
            break

    if score.is_win():
        return name1
    elif score.is_loss():
        return name2
    else:
        return "draw"


fn lpad(var text: String, width: Int) -> String:
    while len(text) < width:
        text = " " + text
    return text


fn rpad(var text: String, width: Int) -> String:
    while len(text) < width:
        text = text + " "
    return text
