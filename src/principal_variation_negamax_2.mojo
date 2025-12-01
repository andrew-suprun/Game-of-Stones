from time import perf_counter_ns
from sys import env_get_int
from logger import Logger, Level

from score import Score
from traits import TTree, TGame, MoveScore


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
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        while True:
            var score = self.root._search(game, Score.loss(), Score.win(), 0, depth, deadline, self.logger)
            var best_move = self._best_move()
            if not score.is_set():
                return best_move
            self.logger.debug("--depth-", depth, " time ", (deadline - perf_counter_ns()) / 1_000_000_000)
            if best_move.score.is_decisive():
                return best_move
            depth += 1

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

    fn _search(mut self, game: Self.G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt, logger: Logger) -> Score:
        if perf_counter_ns() > deadline:
            return Score()

        if not self.children:
            self.children = [Self(move.move, move.score) for move in  game.moves()]

        self.score = Score.loss()
        if depth == max_depth:
            for child in self.children:
                self.score = max(self.score, -child.score)

            return self.score

        sort[Self.greater](self.children)

        if self.children[0].score.is_win():
            return Score.loss()

        for ref child in self.children[1:]:
            if not child.score.is_decisive():
                child.score = Score()

        # Zero window search
        if alpha == beta:
            for ref child in self.children:
                if child.score.is_decisive():
                    self.score = max(self.score, -child.score)
                    if self.score > beta:
                        if logger.level >= Level.TRACE:
                            logger.trace("|  " * depth, depth, " = move [cut]: ", child.move, " zero bound: ", alpha, " score:", child.score, sep="")
                        break

                    if logger.level >= Level.TRACE:
                        logger.trace("|  " * depth, depth, " = move: ", child.move, " zero bound: ", alpha, " score:", child.score, sep="")
                    
                    continue


                var g = game.copy()
                _ = g.play_move(child.move)

                if logger.level >= Level.TRACE:
                    logger.trace("|  " * depth, depth, " > move [zero window]: ", child.move, " zero bound: ", alpha, sep="")
                var score = -child._search(g, -beta, -alpha, depth + 1, max_depth, deadline, logger)
                if logger.level >= Level.TRACE:
                    logger.trace("|  " * depth, depth, " < move [zero window]: ", child.move, " zero bound: ", alpha, "]; score: ", child.score, sep="")

                self.score = max(self.score, score)
                
                if self.score > beta:
                    break

            return self.score

        # Full window search
        var idx = 0
        while idx < len(self.children):
            ref child = self.children[idx]

            if child.score.is_decisive():
                self.score = max(self.score, -child.score)
                alpha = max(alpha, -child.score)
                
                if self.score > beta:
                    if logger.level >= Level.TRACE:
                        logger.trace("|  " * depth, depth, " = move [cut]: ", child.move, " score:", child.score, sep="")
                    break

                if logger.level >= Level.TRACE:
                    logger.trace("|  " * depth, depth, " = move: ", child.move, " score:", child.score, sep="")
                
                idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child.move)

            if logger.level >= Level.TRACE:
                logger.trace("|  " * depth, depth, " > move [full window]: ", child.move, " [", alpha, ":", beta, "]", sep="")
            var score = -child._search(g, -beta, -alpha, depth + 1, max_depth, deadline, logger)
            if logger.level >= Level.TRACE:
                logger.trace("|  " * depth, depth, " < move [full window]: ", child.move, " [", alpha, ":", beta, "]; score: ", child.score, sep="")

            self.score = max(self.score, score)
            alpha = max(alpha, -child.score)
            idx += 1

            if self.score >= alpha:
                break 

        if self.score > beta:
            return self.score

        # Scout search
        while idx < len(self.children):
            ref child = self.children[idx]

            if child.score.is_decisive():
                self.score = max(self.score, -child.score)
                alpha = max(alpha, -child.score)
                
                if self.score > beta:
                    if logger.level >= Level.TRACE:
                        logger.trace("|  " * depth, depth, " = move [cut]: ", child.move, " zero bound: ", alpha, " score:", child.score, sep="")
                    break

                if logger.level >= Level.TRACE:
                    logger.trace("|  " * depth, depth, " = move: ", child.move, " zero bound: ", alpha, " score:", child.score, sep="")
                
                idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child.move)

            if logger.level >= Level.TRACE:
                logger.trace("|  " * depth, depth, " > move [scout zero]: ", child.move, " zero bound: ", alpha, sep="")
            var score = -child._search(g, -alpha, -alpha, depth + 1, max_depth, deadline, logger)
            if logger.level >= Level.TRACE:
                logger.trace("|  " * depth, depth, " < move [scout zero]: ", child.move, " zero bound: ", alpha, "; score: ", child.score, sep="")

            self.score = max(self.score, score)

            if child.score > -alpha:
                alpha = -child.score
                if logger.level >= Level.TRACE:
                    logger.trace("|  " * depth, depth, " DO full search here ", child.move, " [", alpha, ":", beta, "]", sep="")
                ... # TODO Full window re-search
            idx += 1

        return self.score

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
