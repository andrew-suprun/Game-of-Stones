from testing import assert_true
from time import perf_counter_ns

from score import Score
from mcts import Mcts
from gomoku import Gomoku


fn main() raises:
    alias Game = Gomoku[size=19, max_places=8, max_plies=100]
    var game = Game()
    var tree = Mcts[Game, 6]()
    _ = game.play_move("j10")
    _ = game.play_move("i9")
    _ = game.play_move("i10")
    print(game)
    var start = perf_counter_ns()
    for _ in range(100_000):
        _ = tree.expand(game)
    print(perf_counter_ns() - start)

    print(tree.debug_roots())
    print("best move", tree.best_move())
    assert_true(String(tree.best_move()) == "k10")
