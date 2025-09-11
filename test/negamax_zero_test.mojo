from testing import assert_true
from time import perf_counter_ns

from score import Score
from connect6 import Connect6
from negamax_zero import NegamaxZero
from test_game import TestGame, simple_negamax


fn test_mtdf() raises:
    var game = TestGame(depth=5, seed=3)
    var tree = NegamaxZero[TestGame]()
    var deadline = perf_counter_ns() + 1_000_000
    print(game)

    var score = tree.mtdf(game, guess=0, max_depth=5, deadline=deadline)
    var expected = simple_negamax(game, depth=5)
    print("score", score, "expected:", expected)
    assert_true(score == expected)

fn main() raises:
    alias Game = Connect6[size=19, max_moves=8, max_places=6, max_plies=100]
    var game = Game()
    var tree = NegamaxZero[Game]()
    _ = game.play_move("j10")
    _ = game.play_move("i9-i10")
    var move = tree.search(game, 1000)
    print("best move", move.move)
