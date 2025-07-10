from sys import argv
from time import perf_counter_ns
from builtin.io import _fdopen

from game import TGame, Score
from tree import Tree

fn run[Game: TGame, exp_factor: Float64]() raises:
    var log_file = FileHandle()
    var log = False

    var args = argv()
    if len(args) > 1:
        log_file = open(args[1], "w")
        log = True

    var stdin = _fdopen["r"](FileDescriptor(0))

    var game = Game()
    var tree = Tree[Game, exp_factor](Game.Score.draw())

    while True:
        var line: String
        try:
            var text = stdin.readline()
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
            var move = Game.Move(terms[1])
            game.play_move(move)
            tree = Tree[Game, exp_factor](Game.Score.draw())
            if log:
                print(game, file=log_file)
        elif terms[0] == "undo":
            # TODO implement undo
            tree = Tree[Game, exp_factor](Game.Score.draw())
            if log:
                print(game, file=log_file)
        elif terms[0] == "respond":
            var deadline = perf_counter_ns() + Int(terms[1]) * 1_000_000
            var sims = 0
            while perf_counter_ns() < deadline:
                if tree.expand(game):
                    if log:
                        print("DONE", file=log_file)
                    break
                sims += 1
            var move = tree.best_move()
            game.play_move(move)
            tree = Tree[Game, exp_factor](Game.Score.draw())
            print("move", move, game.decision(), sims)
            if log:
                print("move", move, file=log_file)
                print("sims", sims, file=log_file)
                print(game, file=log_file)
        elif terms[0] == "stop":
            if log:
                log_file.close()
            return
        else:
            if log:
                print("unknown", line, file=log_file)
