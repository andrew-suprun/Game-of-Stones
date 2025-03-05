from sys import argv
from time import perf_counter_ns

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

    var game = Game()
    var tree = Tree[Connect6[19, 60, 32]](20)
    
    while True:
        var line: String
        try:
            line = String(input().strip())
        except:
            if log:
                log_file.close()
            return
        if line == "":
            continue
        var terms = line.split(" ")
        if terms[0] == "game-name":
            print("connect6")
        elif terms[0] == "move":
            var move = Move(terms[1])
            game.play_move(move)
            tree.play_move(move)
            if log:
                print("got", line, file=log_file)
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
            print("decision", game.board.decision())

        elif terms[0] == "stop":
            if log:
                log_file.close()
            return
        else:
            print("unknown", line)
