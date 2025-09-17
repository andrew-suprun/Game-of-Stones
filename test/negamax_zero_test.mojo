from testing import assert_true
from time import perf_counter_ns

from score import Score
from connect6 import Connect6
from negamax_zero import NegamaxZero
from test_game import TestGame, simple_negamax


fn test_mtdf() raises:
    # print(game)

    for seed in range(1, 100):
        var game = TestGame(depth=5, seed=seed)
        print("!!! seed", seed)
        for max_depth in range(0, 6):
            var tree = NegamaxZero[TestGame]()
            var deadline = perf_counter_ns() + 1_000_000
            print("max_depth", max_depth)
            var score = -tree.mtdf(game, guess=0, max_depth=max_depth, deadline=deadline)
            print("### SN ###")
            var expected = simple_negamax(game, 0, max_depth)
            print("score", score, "expected:", expected)
            assert_true(score == expected)
