from time import perf_counter_ns

from connect6 import Connect6
from mcts import Mcts

alias Game = Connect6[max_moves=20, max_places=15, max_plies=100]
alias script = "d4 c3-d2 e6-e3 b6-e2 a4-c2 b5-e4 b1-f1 b7-d5 e1-g1 d1-f5 a5-a6 a2-f7 c5-g2 b2-c7 f2-f3"


fn main() raises:
    var game = Game()
    var tree = Mcts[Game, 8]()
    var moves = script.split(" ")
    for move_str in moves:
        _ = game.play_move(Game.Move(String(move_str)))
    print(game)
    var start = perf_counter_ns()
    var move = tree.search(game, 200)
    print("search result", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
    print(tree.debug_roots())
