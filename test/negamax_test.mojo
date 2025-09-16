from testing import assert_true
from time import perf_counter_ns

from score import Score
from negamax import Negamax
from test_game import TestGame, simple_negamax


fn test_negamax() raises:
    var game = TestGame(depth=5, seed=3)
    print(game)
    var tree = Negamax[TestGame]()
    tree._deadline = perf_counter_ns() + 1_000_000_000
    for depth in range(6):
        var score = tree._search(game, Score.loss(), Score.win(), 0, depth)
        var expected = simple_negamax(game, depth)
        print("depth:", depth, "negamax:", score, "expected", expected)
        assert_true(score == expected)


fn main():
    var game = TestGame(depth=5, seed=2)
    print(game)
    var tree = Negamax[TestGame]()
    tree._deadline = perf_counter_ns() + 1_000_000_000
    for depth in range(3, 4):
        var score = tree._search(game, Score.loss(), Score.win(), 0, depth)
        print("depth:", depth)
        print("negamax:", score)
        print("expected:", simple_negamax(game, depth))
