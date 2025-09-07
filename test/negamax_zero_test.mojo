from testing import assert_true
from time import perf_counter_ns

from score import Score
from negamax_zero import mtdf, negamax_zero
from test_game import TestGame, simple_negamax


fn test_negamax_zero() raises:
    var game = TestGame(depth=5, seed=3)
    print(game)


fn main():
    var game = TestGame(depth=5, seed=3)
    print(game)

    var score = mtdf(game, guess=0, max_depth=5)
    print("\nscore", score)
    print("expected:", simple_negamax(game, depth=5))
