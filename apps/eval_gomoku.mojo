from sys import env_get_int
from time import perf_counter_ns

from tree import Tree
from score import Score
from gomoku import Gomoku, Move
from board import Place

alias max_moves = 8
alias c = 20
alias Game = Gomoku[19, max_moves]

fn main() raises:
    var title = String.write(max_moves,  "-", c)
    print(title)
    var game = Game()
    var tree = Tree[Game, Score(c)]()
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("g9")

    while True:
        var sims = 0
        var move: Move
        var value: Score
        var forced = False
        _ = tree.expand(game)
        var best_move = tree.best_move()
        print(sims, best_move, best_move.score())
        var deadline = perf_counter_ns() + 400_000_000
        while perf_counter_ns() < deadline:
            if tree.expand(game):
                forced = True
            sims += 1
            var new_move = tree.best_move()
            if new_move != best_move:
                best_move = new_move
                print(sims, best_move, best_move.score())
            if forced:
                break
        move = tree.best_move()
        print(sims, best_move, best_move.score())
        for ref node in tree.root.children:
            print("    ", node.move, node.move.score(), node.n_sims)
        value = tree.score()
        game.play_move(move)
        tree = Tree[Game, Score(c)]()
        var decision = game.decision()
        print("move", move, decision, sims, value, forced)
        print(game)
        if decision != "no-decision":
            break
