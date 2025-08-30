from time import perf_counter_ns

from gomoku import Gomoku
from negamax import Negamax

alias Game = Gomoku[max_places=20, max_plies=100]
alias script = "d4 d6 f3 b3 c5 b2 c4 e4 b5 e3 e5 d5 c3 c2 f1 e2 d2 f6 e1 c6 g6 a5 e6 f2 b1 c1 a2 g1 g4 d7 g5 c7"

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
    print(game.board.str_scores())
    var start = perf_counter_ns()
    var move = tree.search(game, 2000)
    print("search result", move, "time.ms", (perf_counter_ns() - start) // 1_000_000)
