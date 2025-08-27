from time import perf_counter_ns

from score import draw
from connect6 import Connect6
from mcts import Mcts

alias Game = Connect6[max_moves=20, max_places=15]
alias Tree = Mcts[Game, 10]
alias moves_str = "d4 f5-e2 e6-f6 c4-d2 "
    "b2-e3 e5-f2 b5-g5 b4-c6 c1-c7 b7-g3 d5-g2 d1-f1 b1-g6 e4-g1 c2-f4 c5-g4 b6-e1 d6-d7"


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
    var move = tree.search(game, 10)
    print("move", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
    print()
