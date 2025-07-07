from tree import Tree
from game import Score
from gomoku import Gomoku, Move
from board import Place

alias max_moves = 8
alias c = 0
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

    var score = Score()
    for sims in range(20_000):
        if tree.expand(game):
            break
        var pv_moves = tree.principal_variation()
        # if score != tree.score():
        if True:
            score = tree.score()
            var pv = String()
            # TODO: cannot print List[Game.Move]
            for move in pv_moves:
                move.write_to(pv)
                " ".write_to(pv)
            print(sims, tree.score(), "pv: [", len(pv_moves), "]", pv)
            tree.debug_best_moves()