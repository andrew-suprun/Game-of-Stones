from sys import env_get_int
from time import perf_counter_ns

from tree import Tree
from game import Score
from gomoku import Gomoku, Move
from board import Place

alias max_moves = 8
alias c = 10
alias Game = Gomoku[19, max_moves]

fn main() raises:
    var title = String.write(max_moves,  "-", c)
    print(title)
    var game = Game()
    var tree = Tree[Game, Score(c)]()
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("g9")
    game.play_move("h9")

    var score = Score(0)
    for sims in range(1):
        if tree.expand(game):
            break
        var new_score = tree.score()
        if score != new_score:
            score = new_score
            var pv = String()
            # TODO: cannot print List[Game.Move]
            var pv_moves = tree.principal_variation()
            for move in pv_moves:
                move.write_to(pv)
                " ".write_to(pv)
            var best_move = tree.best_move()
            print(sims, best_move, best_move.score(), "pv: [", len(pv_moves), "]", pv)
            print("tree", tree)
            # tree.debug_best_moves()
    # print("tree", tree)
