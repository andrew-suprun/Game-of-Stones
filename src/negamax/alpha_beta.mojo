from time import perf_counter_ns
from sys import env_get_int

from score import Score
from game import TGame, MoveScore
from negamax import Search

alias trace_level = env_get_int["TRACE_LEVEL", Int.MAX]()

struct AlphaBeta[G: TGame](Search):
    alias Game = G

    var best_move: MoveScore[G.Move]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Alpha-Beta Negamax"

    fn __init__(out self):
        self.best_move = MoveScore[G.Move](G.Move(), Score.no_score())
        self.logger = Logger(prefix="ab: ")

    fn search(mut self, game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        _ = self._search(game, Score.loss(), Score.win(), 0, depth, deadline)
        return self.best_move

    fn _search(mut self, game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        if perf_counter_ns() > deadline:
            return Score.no_score()

        var best_score = Score.loss()
        var moves = game.moves()
        if depth == max_depth:
            for move in moves:
                best_score = max(best_score, move.score)
            return best_score

        sort[Self.greater](moves)
        
        if depth <= trace_level:
            self.logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        for ref move in moves:
            var g = game.copy()
            if depth <= trace_level:
                self.logger.trace("|  " * depth, depth, " > move: ", move.move, " [", alpha, ":", beta, "]", sep="")
            if not move.score.is_decisive():
                _ = g.play_move(move.move)
                move.score = -self._search(g, -beta, -alpha, depth + 1, max_depth, deadline)
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " < move: ", move.move, " [", alpha, ":", beta, "]", " score: ", move.score, sep="")
            else:
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " < decisive move: ", move.move, " [", alpha, ":", beta, "]", " score: ", move.score, sep="")

            if not move.score.is_set():
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " << search: timeout", sep="")
                return Score.no_score()

            if move.score > best_score:
                best_score = move.score
                if depth == 0:
                    self.best_move = move
                    self.logger.debug("best move", self.best_move)
            elif depth == 0:
                self.logger.debug("     move", move)

            if best_score > beta:
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                return best_score
            
            alpha = max(alpha, move.score)

        if depth <= trace_level:
            self.logger.trace("|  " * depth, depth, " << search: score: ", best_score, sep="")
        return best_score

    @staticmethod
    @parameter
    fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score
