from time import perf_counter_ns
from sys import env_get_int
from logger import Logger

from score import Score
from game import TGame, MoveScore
from tree import TTree

alias trace_level = env_get_int["TRACE_LEVEL", Int.MAX]()

alias first_move: Int = 0
alias zero_window: Int = 1
alias full_window: Int = 2


struct PrincipalVariationNegamax[G: TGame](TTree):
    alias Game = G

    var root: PrincipalVariationNode[G]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Principal Variation Negamax With Memory"

    fn __init__(out self):
        self.root = PrincipalVariationNode[G](G.Move(), Score.no_score())
        self.logger = Logger(prefix="pv+: ")

    fn search(mut self, game: G, duration_ms: UInt) -> MoveScore[G.Move]:
        var logger = Logger(prefix="s:  ")
        var best_move = MoveScore[G.Move](G.Move(), Score.loss())
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        while perf_counter_ns() < deadline:
            var start = perf_counter_ns()
            _ = self.root._search(game, Score.loss(), Score.win(), 0, depth, deadline, self.logger)
            best_move = MoveScore[G.Move](self.root.children[0].move, self.root.children[0].score)
            logger.debug("==== depth ", depth, " best-move ", best_move, " time ", (perf_counter_ns() - start) / 1_000_000_000)
            for child in self.root.children:
                if child.score.is_win():
                    best_move = MoveScore[G.Move](child.move, child.score)
                    break
                if not child.score.is_set():
                    break
                if child.score > best_move.score:
                    best_move = MoveScore[G.Move](child.move, child.score)
            if best_move.score.is_decisive():
                break
            depth += 1

        return best_move

struct PrincipalVariationNode[G: TGame](Copyable, Movable, Writable):
    var move: G.Move
    var score: Score
    var children: List[Self]

    fn __init__(out self, move: G.Move, score: Score):
        self.move = move
        self.score = score
        self.children = List[Self]()

    fn _search(mut self, game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt, logger: Logger) -> Score:
        if perf_counter_ns() > deadline:
            return Score.no_score()

        if not self.children:
            var moves = game.moves()
            self.children = List[Self](capacity=len(moves))
            for move in moves:
                self.children.append(Self(move.move, move.score))

        var best_score = Score.loss()
        if depth == max_depth:
            for child in self.children:
                best_score = max(best_score, child.score)
            return best_score

        sort[Self.greater](self.children)

        if depth <= trace_level:
            logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        for ref child in self.children:
            if not child.score.is_decisive():
                child.score = Score.no_score()

        var idx = 0
        var state = first_move
        var g = game.copy()
        while idx < len(self.children):
            ref child = self.children[idx]
            if child.score.is_decisive():
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " = decisive-move: ", child.move, " ", child.score, " [", alpha, ":", beta, "]", sep="")
                if child.score > beta or child.score.is_win():
                    if depth <= trace_level:
                        logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                    return child.score

                alpha = max(alpha, child.score)
                idx += 1
                continue

            if state == zero_window:
                g = game.copy()

            if state != full_window:
                _ = g.play_move(child.move)

            var b = beta
            if state == zero_window:
                b = alpha
            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " > move: ", child.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, sep="")

            start = perf_counter_ns()
            child.score = -child._search(g, -b, -alpha, depth + 1, max_depth, deadline, logger)
            if depth == 0:
                logger.debug("     move ", child.move, " ", child.score, " [", alpha, ":", b, "] time ", (perf_counter_ns() - start) / 1_000_000_000)

            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " < move: ", child.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, "; score: ", child.score, sep="")

            if not child.score.is_set():
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " << search: timeout", sep="")
                return Score.no_score()

            if child.score < alpha:
                state = zero_window
                idx = idx + 1
            elif child.score <= beta and child.score < Score.win():
                if child.score > best_score:
                    if depth == 0:
                        logger.debug("best move ", child.move)
                if state == zero_window and child.score > alpha:
                    state = full_window
                else:
                    state = zero_window
                    idx = idx + 1
                alpha = child.score
            else:
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " << search: cut-score: ", child.score, sep="")
                return child.score
            best_score = max(best_score, child.score)

        if depth <= trace_level:
            logger.trace("|  " * depth, depth, " << search: score: ", best_score, sep="")
        return best_score

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, depth=0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self.move, " ", self.score, "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_to(writer, depth + 1)

    @staticmethod
    @parameter
    fn greater(a: Self, b: Self) -> Bool:
        if a.score.is_set():
            if b.score.is_set():
                return a.score > b.score
            else:
                return True
        else:
            return False
