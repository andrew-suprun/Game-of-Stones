from std.testing import assert_true
from std.time import perf_counter_ns

from engine import TGame, Gomoku, Connect6, Value, MoveValue, Win, Loss, is_win, is_loss, is_draw


def search[Game: TGame](game: Game, depth: Int) -> Value:
    var best_score = Loss
    var moves = game.top_moves()
    if depth == 0:
        for move in moves:
            best_score = max(best_score, move.value)
        return best_score

    for mv in moves:
        if is_win(mv.value):
            return Win
        elif is_loss(mv.value):
            continue
        elif is_draw(mv.value):
            best_score = max(best_score, 0)
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

    test_search[G](["j10", "i9", "i10"], 7)
    test_search[C](["j10", "i9-i10"], 6)
