from time import perf_counter_ns
from sys import env_get_int

from score import Score
from game import TGame, MoveScore
from negamax import Negamax

alias trace_level = env_get_int["TRACE_LEVEL", Int.MAX]()

alias first_move: Int = 0
alias zero_window: Int = 1
alias full_window: Int = 2


struct PrincipalVariation[G: TGame](Negamax):
    alias Game = G

    var best_move: MoveScore[G.Move]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Principal Variation Negamax"

    fn __init__(out self):
        self.best_move = MoveScore[G.Move](G.Move(), Score.no_score())
        self.logger = Logger(prefix="pv: ")

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

        var idx = 0
        var state = first_move
        var g = game.copy()
        if depth <= trace_level:
            self.logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        while idx < len(moves):
            ref move = moves[idx]
            if move.score.is_decisive():
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " = decisive-move: ", move, " [", alpha, ":", beta, "]", sep="")
                if move.score.is_win():
                    if depth <= trace_level:
                        self.logger.trace("|  " * depth, depth, " << search: win", sep="")
                    if depth == 0:
                        self.best_move = MoveScore[G.Move](move.move, Score.win())
                    return Score.win()
                if move.score > beta:
                    if depth <= trace_level:
                        self.logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                    return move.score

                alpha = max(alpha, move.score)
                idx += 1
                continue

            if state == zero_window:
                g = game.copy()

            if state != full_window:
                _ = g.play_move(move.move)

            var b = beta
            if state == zero_window:
                b = alpha
            if depth <= trace_level:
                self.logger.trace("|  " * depth, depth, " > move: ", move.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, sep="")
                    
            move.score = -self._search(g, -b, -alpha, depth + 1, max_depth, deadline)

            if depth <= trace_level:
                self.logger.trace("|  " * depth, depth, " < move: ", move.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, "; score: ", move.score, sep="")

            if not move.score.is_set():
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " << search: timeout", sep="")
                return Score.no_score()

            if move.score < alpha:
                if depth == 0:
                    self.logger.debug("     move", move)
                state = zero_window
                idx = idx + 1
            elif move.score <= beta:
                if move.score > best_score:
                    if depth == 0:
                        self.best_move = move
                        self.logger.debug("best move", self.best_move)
                elif depth == 0:
                    self.logger.debug("     move", move)
                if state == zero_window and move.score > alpha:
                    state = full_window
                else:
                    state = zero_window
                    idx = idx + 1
                alpha = move.score
            else:
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " << search: cut-score: ", move.score, sep="")
                return move.score
            best_score = max(best_score, move.score)


        if depth <= trace_level:
            self.logger.trace("|  " * depth, depth, " << search: score: ", best_score, sep="")
        return best_score

    @staticmethod
    @parameter
    fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score
