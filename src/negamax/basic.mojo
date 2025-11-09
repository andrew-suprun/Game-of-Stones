from time import perf_counter_ns

from score import Score
from game import TGame, MoveScore
from negamax import Search


struct Basic[G: TGame](Search):
    alias Game = G

    var best_move: G.Move

    @staticmethod
    fn name() -> StaticString:
        return "Basic Negamax"

    fn __init__(out self):
        self.best_move = G.Move()

    fn search(mut self, game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        var score = self._search(game, Score.loss(), Score.win(), 0, depth, deadline)
        return MoveScore(self.best_move, score)

    fn _search(mut self, game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        if perf_counter_ns() > deadline:
            return Score.no_score()

        var best_score = Score.loss()
        var moves = game.moves()
        for ref move in moves:
            var g = game.copy()
            if depth < max_depth and not move.score.is_decisive():
                _ = g.play_move(move.move)
                move.score = -self._search(g, Score.loss(), Score.win(), depth + 1, max_depth, deadline)
            if not move.score.is_set():
                return Score.no_score()

            if move.score > best_score:
                best_score = move.score
                if depth == 0:
                    self.best_move = move.move

        return best_score

    @staticmethod
    @parameter
    fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score
