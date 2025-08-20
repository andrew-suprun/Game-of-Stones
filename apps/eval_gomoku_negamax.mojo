from time import perf_counter_ns

from score import draw
from gomoku import Gomoku
from negamax import Negamax

alias Game = Gomoku[max_places=15]
alias Tree = Negamax[Game, max_moves=32]
alias moves_str = "j10 j9 i10 i9 k10 h10 k9 h9 j8 l10 k8 g9 f9"


fn main() raises:
    var game = Tree.Game()
    var tree = Tree()
    var moves = moves_str.split(" ")
    for move in moves:
        _ = game.play_move(Tree.Game.Move(move))
    print(game)
    var start = perf_counter_ns()
    var move = tree.search(game, 100)
    print("move", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
    print()
