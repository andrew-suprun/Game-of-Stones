from sys import env_get_int
from time import perf_counter_ns

from tree import Tree
from game import Score
from connect6 import Connect6, Move
from board import Place

alias max_moves = 8
alias c = 40
alias Game = Connect6[19, 32, 20]

fn main() raises:
    var title = String.write(max_moves,  "-", c)
    print(title)
    var game = Game()
    var tree = Tree[Game, Score(c)]()
    game.play_move("j10")
    game.play_move("i9-i10")

    for _ in range(1):
        if tree.expand(game):
            break
