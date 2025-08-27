from time import perf_counter_ns

from connect6 import Connect6
from mcts import Mcts

alias Game = Connect6[max_moves=20, max_places=15]
alias Tree = Mcts[Game, 10]
alias moves_str = "j10 l11-k8 k12-l12 i10-j8 m12-m13 h8-i8"


fn main() raises:
    var game = Tree.Game()
    var tree = Tree()
    var moves = moves_str.split(" ")
    for move in moves:
        _ = game.play_move(Tree.Game.Move(move))
        print(move)
        print(game)
    print(game)
    var start = perf_counter_ns()
    var move = tree.search(game, 1000)
    print("move", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
    # print(tree)
