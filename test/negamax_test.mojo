from std.testing import assert_true
from std.time import perf_counter_ns
from std.reflection import reflect

from traits import TGame
from gomoku import Gomoku
from connect6 import Connect6
from negamax import search


def test_search[Game: TGame](moves: List[String], max_depth: Int) raises:
    print(t"game: {reflect[Game]().base_name()}")
    for depth in range(1, max_depth):
        var game = Game()
        for move in moves:
            game.play_move(Game.Move(move))
        if depth == 1:
            print(game)
        var start = perf_counter_ns()
        var score = search(game, depth)
        print(t"depth {depth}: score {score}, time {Float64(perf_counter_ns() - start)/1_000_000_000}s")


def main() raises:
    comptime G = Gomoku[size=19, max_places=16, max_plies=100]
    comptime C = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]

    test_search[G](["j10", "i9", "i10"], 7)
    test_search[C](["j10", "i9-i10"], 6)
