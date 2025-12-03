from time import perf_counter_ns
from sys import env_get_int
from logger import Logger, Level

from score import Score
from traits import TTree, TGame, MoveScore


# TODO Use this after unpacked arguments are supported
fn debug[*Ts: Writable](logger: Logger, depth: Int, *values: *Ts):
    if not logger._is_disabled[Level.DEBUG]():
        logger.debug("|  " * depth, depth, *values, sep="")


fn trace[*Ts: Writable](logger: Logger, depth: Int, *values: *Ts):
    if not logger._is_disabled[Level.DEBUG]():
        logger.trace("|  " * depth, depth, *values, sep="")


struct PrincipalVariationNegamax2[G: TGame](TTree):
    alias Game = Self.G

    var root: PrincipalVariationNode[Self.G]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Principal Variation Negamax With Memory"

    fn __init__(out self):
        self.root = PrincipalVariationNode[Self.G](Self.G.Move(), Score())
        self.logger = Logger(prefix="pvs2: ")

    fn search(mut self, game: Self.G, duration_ms: UInt) -> MoveScore[Self.G.Move]:
        var max_depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        while True:
            var within_deadline = self.root._search(game, Score.loss(), Score.win(), 0, max_depth, deadline, self.logger)
            var best_move = self._best_move()
            if not within_deadline:
                return best_move
            self.logger.debug("=== max depth:", max_depth, " move:", best_move, " time remaining:", (deadline - perf_counter_ns()) / 1_000_000_000)
            if best_move.score.is_decisive():
                return best_move
            max_depth += 1

    fn _best_move(self) -> MoveScore[Self.G.Move]:
        var best_move = self.root.children[0].move
        var best_score = self.root.children[0].score
        for node in self.root.children:
            if best_score < node.score:
                best_move = node.move
                best_score = node.score
        return MoveScore(best_move, best_score)


struct PrincipalVariationNode[G: TGame](Copyable, Movable, Writable):
    var move: Self.G.Move
    var score: Score
    var children: List[Self]

    fn __init__(out self, move: Self.G.Move, score: Score):
        self.move = move
        self.score = score
        self.children = List[Self]()

    fn _search(mut self, game: Self.G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt, logger: Logger, out within_deadline: Bool):
        if perf_counter_ns() > deadline:
            if not logger._is_disabled[Level.DEBUG]():
                logger.debug("|  " * depth, depth, " = [timeout] ", sep="")
            return False

        if not self.children:
            self.children = [Self(move.move, move.score) for move in game.moves()]

        if depth == max_depth:
            self.score = Score.win()
            for child in self.children:
                self.score = min(self.score, -child.score)
            if not logger._is_disabled[Level.TRACE]():
                logger.trace("|  " * depth, depth, " = [max depth] ", self.move, " score: ", self.score, sep="")
            return True

        if not logger._is_disabled[Level.TRACE]():
            logger.trace("|  " * depth, depth, " > ", self.move, " [", alpha, ":", beta, "]", sep="")

        sort[Self.greater](self.children)

        if self.children[0].score.is_win():
            self.score = Score.loss()
            if not logger._is_disabled[Level.TRACE]():
                logger.trace("|  " * depth, depth, " < [decisive] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
            return True

        for ref child in self.children[1:]:
            if not child.score.is_decisive():
                child.score = Score()

        var best_score = Score.loss()

        # Zero window search
        if alpha == beta:
            for ref child in self.children:
                if child.score.is_decisive():
                    self.score = min(self.score, -child.score)
                    if child.score > beta:
                        self.score = -best_score

                        if not logger._is_disabled[Level.TRACE]():
                            logger.trace("|  " * depth, depth, " < [cut] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
                        return True

                    continue

                var g = game.copy()
                _ = g.play_move(child.move)

                if not child._search(g, -alpha, -alpha, depth + 1, max_depth, deadline, logger):
                    return False

                if best_score < child.score:
                    best_score = child.score
                    alpha = max(alpha, best_score)

                if child.score > beta or child.score.is_win():
                    self.score = -best_score

                    if not logger._is_disabled[Level.TRACE]():
                        logger.trace("|  " * depth, depth, " < [zero window cut] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
                    return True

            self.score = -best_score
            if not logger._is_disabled[Level.TRACE]():
                logger.trace("|  " * depth, depth, " < [zero window] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
            return True

        var idx = 0
        # Full window search
        while idx < len(self.children):
            ref child = self.children[idx]

            if child.score.is_decisive():
                if best_score < child.score:
                    best_score = child.score
                    alpha = max(alpha, child.score)

                if child.score > beta:
                    self.score = -best_score
                    if not logger._is_disabled[Level.TRACE]():
                        logger.trace("|  " * depth, depth, " < [full window cut] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
                    return True

                idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child.move)

            if not child._search(g, -beta, -alpha, depth + 1, max_depth, deadline, logger):
                return False

            if best_score < child.score:
                best_score = child.score
                alpha = max(alpha, best_score)

            if child.score > beta or child.score.is_win():
                self.score = -child.score
                if not logger._is_disabled[Level.TRACE]():
                    logger.trace("|  " * depth, depth, " < [full window] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
                return True

            idx += 1

            if alpha != Score.loss() and child.score >= alpha:
                break

        # Scout search
        while idx < len(self.children):
            ref child = self.children[idx]

            if child.score.is_decisive():
                self.score = min(self.score, -child.score)
                alpha = max(alpha, child.score)

                if child.score > beta:
                    self.score = -best_score
                    if not logger._is_disabled[Level.TRACE]():
                        logger.trace("|  " * depth, depth, " < [decisive scout cut] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
                    return True

                idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child.move)

            if not child._search(g, -alpha, -alpha, depth + 1, max_depth, deadline, logger):
                return False

            if best_score < child.score:
                best_score = child.score
                alpha = max(alpha, best_score)

            if child.score.is_win():
                self.score = Score.loss()
                if not logger._is_disabled[Level.TRACE]():
                    logger.trace("|  " * depth, depth, " < [scout zero] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
                return True

            if child.score > beta and depth < max_depth - 1:
                if not child._search(g, -beta, -alpha, depth + 1, max_depth, deadline, logger):
                    return False

                if best_score < child.score:
                    best_score = child.score
                    alpha = max(alpha, best_score)

                if child.score > beta or child.score.is_win():
                    self.score = -best_score
                    if not logger._is_disabled[Level.TRACE]():
                        logger.trace("|  " * depth, depth, " < [scout full] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
                    return True

            idx += 1

        self.score = -best_score
        if not logger._is_disabled[Level.TRACE]():
            logger.trace("|  " * depth, depth, " < [scout] ", self.move, " [", alpha, ":", beta, "]; score: ", self.score, sep="")
        return True

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
        return a.score > b.score
