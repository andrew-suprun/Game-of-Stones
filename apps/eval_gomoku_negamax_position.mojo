from time import perf_counter_ns

from gomoku import Gomoku
from negamax import Negamax

alias Game = Gomoku[max_places=20]
alias script = "d4 b2 c4 f3 e3 e5 c5 f2 d3 f4 f5 c3 e4 g6 d6 d5 b6 a7 b4 a4 c2 b1 b5 e2 a6 c6 b7 b3 a3 e7 f6 g1 d2 d7 a2 g5 a5 d1 e6"

fn main() raises:
    var game = Game()
    var tree = Negamax[Game]()
    var moves = script.split(" ")
    for move_str in moves:
        var result = game.play_move(Game.Move(String(move_str)))
        if result.is_decisive():
            print("exiting without search")
            return
    print(game)
    var start = perf_counter_ns()
    var move = tree.search(game, 200)
    print("search result", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
