from tree import TTree
from score import Score, is_win, is_loss, is_decisive
from board import first

alias timeout = 200
alias black = True
alias white = False


fn run[T1: TTree, T2: TTree](name1: String, name2: String, openings: List[List[String]]) raises:
    var stats = {name1: 0, name2: 0, "draw": 0}
    for opening in openings:
        sim_opening[T1, T2](name1, name2, opening, stats)
        sim_opening[T2, T1](name2, name1, opening, stats)


fn sim_opening[T1: TTree, T2: TTree](name1: String, name2: String, opening: List[String], mut stats: Dict[String, Int],) raises:
    print()
    print(name1, "vs.", name2)
    print()

    var g1 = T1.Game()
    var g2 = T2.Game()
    var t1 = T1()
    var t2 = T2()
    var turn = first

    for move in opening:
        _ = g1.play_move(T1.Game.Move(move))
        _ = g2.play_move(T2.Game.Move(move))

    print("opening:", end="")
    for move in opening:
        print("", move, end="")
    print()

    var score: Score

    while True:
        var move: String
        if turn == first:
            var result = t1.search(g1, timeout)
            move = String(result.move)
            print("move", move)
        else:
            var result = t2.search(g2, timeout)
            move = String(result.move)
            print("move", move)
        score = g1.play_move(T1.Game.Move(move))
        _ = g2.play_move(T2.Game.Move(move))
        t1 = T1()
        t2 = T2()
        turn = 1 - turn

        if is_decisive(score):
            break

    if is_win(score):
        stats[name1] += 1
    elif is_loss(score):
        stats[name2] += 1
    else:
        stats["draw"] += 1

    # print("\x1b[1G", end="")
    for item in stats.items():
        print(item.key, item.value, "", end="")
    print()
