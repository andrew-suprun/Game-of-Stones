from sys import argv
from time import perf_counter_ns

from game import TGame, Score, Decision, undecided, first_wins, second_wins
from tree import TTree

fn run[Tree: TTree](no_legal_moves_score: Score) raises:
    var log_file = FileHandle()
    var log = False

    var args = argv()
    if len(args) > 1:
        log_file = open(args[1], "w")
        log = True

    var game = Tree.Game()
    var tree = Tree(no_legal_moves_score)

    while True:
        var line: String
        try:
            var text = input()
            line = String(text.strip())
        except:
            if log:
                print("ERROR", file=log_file)
                log_file.close()
            return
        if line == "":
            continue
        if log:
            print("got", line, file=log_file)
        var terms = line.split(" ")
        if terms[0] == "move":
            var move = Tree.Game.Move(terms[1])
            game.play_move(move)
            tree = Tree(no_legal_moves_score)
            if log:
                print(game, file=log_file)
        elif terms[0] == "undo":
            # TODO implement undo
            tree = Tree(no_legal_moves_score)
            if log:
                print(game, file=log_file)
        elif terms[0] == "respond":
            var (score, pv) = tree.search(game, Int(terms[1]))
            debug_assert(len(pv) > 0)
            game.play_move(pv[0])
            print("move", pv[0], score, str_decision(game.decision()))
            if log:
                print("pv: ", end="", file=log_file)
                for move in pv:
                    print(move, "", end="", file=log_file)
                print(game, file=log_file)
        elif terms[0] == "stop":
            if log:
                log_file.close()
            return
        else:
            if log:
                print("unknown", line, file=log_file)

fn str_decision(d: Decision) -> StaticString:
    if d == undecided:
        return "no-decision"
    elif d == first_wins:
        return "first-win"
    elif d == second_wins:
        return "second-win"
    else:
        return "draw"