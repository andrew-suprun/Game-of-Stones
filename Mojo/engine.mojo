from sys import argv
from time import perf_counter_ns
from builtin.io import _fdopen

from connect6 import Connect6, Move
from tree import Tree

alias Game = Connect6[19, 60, 32]
alias game_name = "connect6"

var log_file = FileHandle()
var log = False

def main():
    var args = argv()
    if len(args) > 1:
        log_file = open(args[1], "w")
        log = True

    var stdin = _fdopen["r"](0)


    var game = Game()
    var tree = Tree[Connect6[19, 60, 32]](20)
    
    while True:
        var line: String
        try:
            if log:
                print("read line 1", file=log_file)
            var text = stdin.readline()
            # var text = input()
            if log:
                print("read line 2", file=log_file)
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
        if terms[0] == "game-name":
            print("game-name connect6")
        elif terms[0] == "move":
            var move = Move(terms[1])
            game.play_move(move)
            tree.play_move(move)
            if log:
                print(game.board, file=log_file)
        elif terms[0] == "respond":
            var deadline = perf_counter_ns() + Int(terms[1]) * 1_000_000
            while perf_counter_ns() < deadline:
                if tree.expand(game):
                    break
            var move = tree.best_move()
            game.play_move(move)
            tree.play_move(move)
            print("move", move)
            if log:
                print("move", move, file=log_file)
                print(game.board, file=log_file)
        elif terms[0] == "decision":
            print("decision no-decision")
            # print("decision", game.board.decision())

        elif terms[0] == "stop":
            if log:
                log_file.close()
            return
        else:
            if log:
                print("unknown", line, file=log_file)
