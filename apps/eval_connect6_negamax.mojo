from time import perf_counter_ns

from score import draw
from connect6 import Connect6
from negamax import Negamax

alias Game = Connect6[max_places=15]
alias Tree = Negamax[Game, max_moves=32]
alias moves_str = "j10 c18-m19 k9-k10 k12-m10 j9-l11 m9-m12 j8-j11 j6-j12 h12-i11"


fn main() raises:
    var game = Tree.Game()
    var tree = Tree()
    var moves = moves_str.split(" ")
    for move in moves:
        game.play_move(Tree.Game.Move(move))
        print(game)
    print(game)
    var start = perf_counter_ns()
    var move = tree.search(game, 100)
    print("move", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
    print()
