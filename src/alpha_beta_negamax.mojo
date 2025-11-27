from time import perf_counter_ns
from sys import env_get_int
from logger import Logger

from score import Score
from traits import TTree, TGame, MoveScore

alias trace_level = env_get_int["TRACE_LEVEL", Int.MAX]()


struct AlphaBetaNegamax[G: TGame](TTree):
    alias Game = Self.G

    var root: AlphaBetaNode[Self.G]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Alpha-Beta Negamax With Memory"

    fn __init__(out self):
        self.root = AlphaBetaNode[Self.G](Self.G.Move(), Score())
        self.logger = Logger(prefix="abs: ")

    fn search(mut self, game: Self.G, duration_ms: UInt) -> MoveScore[Self.G.Move]:
        var best_move = MoveScore(Self.G.Move(), Score.loss())
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        while True:
            var score = self.root._search(game, best_move, Score.loss(), Score.win(), 0, depth, deadline, self.logger)
            if not score.is_set():
                return best_move
            self.logger.debug("--depth-", depth, best_move, " time ", (deadline - perf_counter_ns()) / 1_000_000_000)
            if best_move.score.is_decisive():
                return best_move
            depth += 1


struct AlphaBetaNode[G: TGame](Copyable, Movable, Writable):
    var move: Self.G.Move
    var score: Score
    var children: List[Self]

    fn __init__(out self, move: Self.G.Move, score: Score):
        self.move = move
        self.score = score
        self.children = List[Self]()

    fn _search(mut self, game: Self.G, mut best_move: MoveScore[Self.G.Move], var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt, logger: Logger) -> Score:
        if perf_counter_ns() > deadline:
            return Score()

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
        if depth == 0:
            best_move = MoveScore(self.children[0].move, self.children[0].score)
            logger.debug("best move", best_move)

        if depth <= trace_level:
            logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        for ref child in self.children:
            if not child.score.is_decisive():
                child.score = Score()

        for ref child in self.children:
            var g = game.copy()
            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " > move: ", child.move, " [", alpha, ":", beta, "]", sep="")
            if not child.score.is_decisive():
                _ = g.play_move(child.move)
                child.score = -child._search(g, best_move, -beta, -alpha, depth + 1, max_depth, deadline, logger)
                # if depth == 0:
                #     logger.debug("     move", child.move, child.score, " [", alpha, ":", beta, "] time ", (deadline - perf_counter_ns()) / 1_000_000_000)
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " < move: ", child.move, " [", alpha, ":", beta, "] score: ", child.score, sep="")
            else:
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " < decisive move: ", child.move, " ", child.score, " [", alpha, ":", beta, "]", sep="")

            if not child.score.is_set():
                return Score()

            if child.score > best_score:
                best_score = child.score
                if depth == 0:
                    best_move = MoveScore(child.move, child.score)
                    logger.debug("best move", best_move)

            if best_score > beta or best_score.is_win():
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                return best_score

            alpha = max(alpha, child.score)

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
        return a.score > b.score
