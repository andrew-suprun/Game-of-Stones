from std.testing import assert_true
from std.time import perf_counter_ns

from engine import TGame, Gomoku, Connect6, Score, MoveScore


def search[Game: TGame](game: Game, depth: Int) -> Score:
    var best_score = Score.loss()
    var moves = game.top_moves()
    if depth == 0:
        for move in moves:
            best_score = max(best_score, move.score)
        return best_score

    for mv in moves:
        if mv.score.is_win():
            return Score.win()
        elif mv.score.is_loss():
            continue
        elif mv.score.is_draw():
            best_score = best_score.max(Score(0))
        else:
            var g = game.copy()
            g.play_move(mv.move)
            var child_score = search(g, depth - 1)
            best_score = max(best_score, -child_score)
    return best_score


def test_search[Game: TGame](moves: List[String], max_depth: Int) raises:
    print(t"game: {reflect[Game].base_name()}")
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
    comptime G = Gomoku[size=19, max_moves=16]
    comptime C = Connect6[size=19, max_moves=16, max_places=12]

    test_search[G](["j10", "i9", "i10"], 6)
    test_search[C](["j10", "i9-i10"], 5)
