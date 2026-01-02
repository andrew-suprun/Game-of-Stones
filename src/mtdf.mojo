from time import perf_counter_ns
from sys import env_get_int
from logger import Logger, Level

from score import Score
from traits import TTree, TGame, MoveScore


comptime trace_level = env_get_int["TRACE_LEVEL", Int.MAX]()


struct Mtdf[G: TGame](TTree):
    comptime Game = Self.G

    var root: MtdfNode[Self.G]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "MTD(f)"

    fn __init__(out self):
        self.root = MtdfNode[Self.G](Self.G.Move(), Score())
        self.logger = Logger(prefix="mtdf: ")

    fn search(mut self, game: Self.G, duration_ms: UInt) -> MoveScore[Self.G.Move]:
        var max_depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        while True:
            var score = Score(0)
            var start: UInt = 0
            if not self.logger._is_disabled[Level.DEBUG]():
                start = perf_counter_ns()

            while True:
                self.logger.debug(">>> depth:", max_depth, " alpha:", score)
                if not self.root._search(game, score, 0, max_depth, deadline, self.logger):
                    var best_move = self._best_move()
                    self.logger.debug("=== result:", max_depth, " move:", best_move, " time:", (perf_counter_ns() - start) / 1_000_000_000)
                    return best_move
                var best_move = self._best_move()
                self.logger.debug("<<< depth:", max_depth, " move:", best_move, " time:", (perf_counter_ns() - start) / 1_000_000_000)
                if best_move.score == score:
                    break
                score = best_move.score

            var best_move = self._best_move()
            if best_move.score.is_decisive():
                self.logger.debug("=== decisive result:", max_depth, " move:", best_move, " time:", (perf_counter_ns() - start) / 1_000_000_000)
                return best_move
            else:
                self.logger.debug("=== depth:", max_depth, " move:", best_move, " time:", (perf_counter_ns() - start) / 1_000_000_000)
            max_depth += 1

    fn _best_move(self) -> MoveScore[Self.G.Move]:
        var best_move = self.root.children[0].move
        var best_score = self.root.children[0].score
        for node in self.root.children:
            self.logger.debug("  child:", node.move, node.score)
            if best_score < node.score:
                best_move = node.move
                best_score = node.score
        return MoveScore(best_move, best_score)


struct MtdfNode[G: TGame](Copyable, Writable):
    var move: Self.G.Move
    var score: Score
    var children: List[Self]

    fn __init__(out self, move: Self.G.Move, score: Score):
        self.move = move
        self.score = score
        self.children = List[Self]()

    fn _search(mut self, game: Self.G, alpha: Score, depth: Int, max_depth: Int, deadline: UInt, logger: Logger, out within_deadline: Bool):
        if perf_counter_ns() > deadline:
            if not logger._is_disabled[Level.TRACE]() and trace_level >= depth:
                logger.trace("|  " * depth, depth, " = [timeout] ", sep="")
            return False

        if not self.children:
            self.children = [Self(move.move, move.score) for move in game.moves()]

        if depth == max_depth:
            self.score = Score.win()
            for child in self.children:
                self.score = min(self.score, -child.score)
            if not logger._is_disabled[Level.TRACE]() and trace_level >= depth:
                logger.trace("|  " * depth, depth, " = [max depth]; score: ", -self.score, sep="")
            return True

        sort[Self.greater](self.children)

        if self.children[0].score.is_win():
            self.score = Score.loss()
            if not logger._is_disabled[Level.TRACE]() and trace_level >= depth:
                logger.trace("|  " * depth, depth, " = [decisive] ", self.move, " alpha: ", alpha, "; score: ", self.score, sep="")
            return True

        var start: UInt = 0
        var best_score = Score.loss()

        for ref child in self.children:
            if child.score.is_decisive():
                if not logger._is_disabled[Level.TRACE]() and trace_level >= depth:
                    logger.trace("|  " * depth, depth, " = [decisive] ", child.move, " score: ", child.score, sep="")
                if best_score < child.score:
                    best_score = child.score
                if child.score > alpha or child.score.is_win():
                    self.score = -best_score
                    return True
                continue

            var g = game.copy()
            _ = g.play_move(child.move)

            if not logger._is_disabled[Level.TRACE]() and trace_level >= depth:
                logger.trace("|  " * depth, depth, " > ", child.move, "; alpha: ", alpha, sep="")
                start = perf_counter_ns()
            if not child._search(g, -alpha, depth + 1, max_depth, deadline, logger):
                return False

            if best_score < child.score:
                best_score = child.score

            if child.score > alpha or child.score.is_win():
                self.score = -child.score
                if not logger._is_disabled[Level.TRACE]() and trace_level >= depth:
                    logger.trace("|  " * depth, depth, " < [cut] ", child.move, "; score: ", child.score, "; time: ", (perf_counter_ns() - start) / 1_000_000_000, sep="")
                return True
            else:
                if not logger._is_disabled[Level.TRACE]() and trace_level >= depth:
                    logger.trace("|  " * depth, depth, " < ", child.move, "; score: ", child.score, "; time: ", (perf_counter_ns() - start) / 1_000_000_000, sep="")
        self.score = -best_score
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
