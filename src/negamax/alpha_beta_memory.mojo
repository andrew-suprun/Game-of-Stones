from time import perf_counter_ns
from sys import env_get_int

from score import Score
from game import TGame, MoveScore
from negamax import Search

alias trace_level = env_get_int["TRACE_LEVEL", Int.MAX]()


struct AlphaBetaMemory[G: TGame](Search):
    alias Game = G

    var root: AlphaBetaNode[G]
    var best_move: MoveScore[G.Move]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Alpha-Beta Negamax With Memory"

    fn __init__(out self):
        self.root = AlphaBetaNode[G](G.Move(), Score.no_score())
        self.best_move = MoveScore[G.Move](G.Move(), Score.no_score())
        self.logger = Logger(prefix="ab+: ")

    fn search(mut self, game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        _ = self.root._search(game, Score.loss(), Score.win(), 0, depth, deadline, self.best_move, self.logger)
        return self.best_move


struct AlphaBetaNode[G: TGame](Copyable, Movable, Writable):
    var move: G.Move
    var score: Score
    var children: List[Self]

    fn __init__(out self, move: G.Move, score: Score):
        self.move = move
        self.score = score
        self.children = List[Self]()

    fn _search(mut self, game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt, mut best_move: MoveScore[G.Move], logger: Logger) -> Score:
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

        for ref child in self.children:
            var g = game.copy()
            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " > move: ", child.move, " [", alpha, ":", beta, "]", sep="")
            if not child.score.is_decisive():
                _ = g.play_move(child.move)
                child.score = -child._search(g, -beta, -alpha, depth + 1, max_depth, deadline, best_move, logger)
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " < move: ", child.move, " [", alpha, ":", beta, "] score: ", child.score, sep="")
            else:
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " < decisive move: ", child.move, " ", child.score, " [", alpha, ":", beta, "]", sep="")

            if not child.score.is_set():
                return Score.no_score()

            if child.score > best_score:
                best_score = child.score
                if depth == 0:
                    best_move = MoveScore(child.move, child.score)
                    logger.debug("best move", best_move)
            elif depth == 0:
                logger.debug("     move", child.move, child.score)

            if best_score > beta:
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
        if a.score.is_set():
            if b.score.is_set():
                return a.score > b.score
            else:
                return True
        else:
            return False
