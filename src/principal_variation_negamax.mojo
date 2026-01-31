from time import perf_counter_ns
from sys import env_get_int
from logger import Logger

from score import Score
from traits import TTree, TGame, MoveScore


struct PrincipalVariationNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: PrincipalVariationNode[Self.G]

    @staticmethod
    fn name() -> StaticString:
        return "Principal Variation Negamax With Memory"

    fn __init__(out self):
        self.root = PrincipalVariationNode[Self.G](Self.G.Move(), Score())

    fn search(mut self, game: Self.G, duration_ms: UInt) -> MoveScore[Self.G.Move]:
        var logger = Logger(prefix="pvs: ")
        var best_move = MoveScore(Self.G.Move(), Score.loss())
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        var start = perf_counter_ns()
        while True:
            var score = self.root._search(game, best_move, Score.loss(), Score.win(), 0, depth, deadline, logger)
            if not score.is_set():
                return best_move
            logger.debug("=== max depth: ", depth, " move:", best_move, " time:", (perf_counter_ns() - start) / 1_000_000_000)
            if best_move.score.is_decisive():
                return best_move
            depth += 1


struct PrincipalVariationNode[G: TGame](Copyable, Writable):
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
            self.children = [Self(move.move, move.score) for move in game.moves()]

        best_move = MoveScore(self.children[0].move, self.children[0].score)
        var best_score = Score.loss()

        if depth == max_depth:
            for child in self.children:
                best_score = max(best_score, child.score)
            return best_score

        sort[Self.greater](self.children)

        if self.children[0].score.is_win():
            return Score.win()

        for ref child in self.children[1:]:
            if not child.score.is_decisive():
                child.score = Score()

        var deeper_best_move = MoveScore(Self.G.Move(), 0)
        var idx = 0

         # Full window search
        while idx < len(self.children):
            ref child = self.children[idx]

            if child.score.is_decisive():
                if best_score < child.score:
                    best_score = child.score
                    alpha = max(alpha, child.score)
                if child.score > beta or child.score.is_win():
                    return best_score

                idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child.move)

            child.score = -child._search(g, deeper_best_move, -beta, -alpha, depth + 1, max_depth, deadline, logger)
            if not child.score.is_set():
                return Score()

            if best_score < child.score:
                best_score = child.score
                best_move = MoveScore(child.move, child.score)
                alpha = max(alpha, best_score)

            if child.score > beta or child.score.is_win():
                return best_score

            idx += 1

            if alpha != Score.loss() and child.score >= alpha:
                break

        # Scout search
        while idx < len(self.children):
            ref child = self.children[idx]

            if child.score.is_decisive():
                if best_score < child.score:
                    best_score = child.score
                    alpha = max(alpha, best_score)
                if child.score > beta or child.score.is_win():
                    return best_score

                idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child.move)

            child.score = -child._search(g, deeper_best_move, -alpha, -alpha, depth + 1, max_depth, deadline, logger)

            if best_score < child.score:
                best_score = child.score
                best_move = MoveScore(child.move, child.score)

            if child.score > beta or child.score.is_win():
                return best_score

            if best_score > alpha and depth < max_depth - 1:
                alpha = best_score
                child.score = -child._search(g, deeper_best_move, -beta, -alpha, depth + 1, max_depth, deadline, logger)

                if best_score < child.score:
                    best_score = child.score
                    best_move = MoveScore(child.move, child.score)
                    alpha = max(alpha, best_score)

                if child.score > beta or child.score.is_win():
                    return best_score

            idx += 1

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
