from time import perf_counter_ns

from game_of_stones import game_of_stones
from score import draw
from negamax import Negamax
from gomoku import Gomoku

alias Game = Gomoku[values = List[Float32](0, 1, 5, 25, 125), max_places = 15]
alias Tree = Negamax[Game, max_moves = 32, no_legal_moves_decision = draw]
alias moves_str = "j10 j9 i10 i9 k10 h10 k9 h9 j8 l10 k8 g9 f9"

fn main() raises:
    var game = Tree.Game()
    var tree = Tree()
    var moves = moves_str.split(" ")
    for move in moves:
        game.play_move(Tree.Game.Move(move))
    print(game)
    var start = perf_counter_ns()
    var (score, pv) = tree.search(game, 2000)
    print("score", score, "time.ms", (perf_counter_ns() - start) // 1_000_000, "pv:", end="")
    for move in pv:
        print("", move, end="")
    print()