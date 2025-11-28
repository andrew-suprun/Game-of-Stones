from time import perf_counter_ns
from sys import env_get_int
from logger import Logger

from score import Score
from traits import TTree, TGame, MoveScore

alias trace_level = env_get_int["TRACE_LEVEL", Int.MAX]()

alias first_move: Int = 0
alias zero_window: Int = 1
alias full_window: Int = 2


@fieldwise_init
struct PrincipalVariationNegamax2[G: TGame](TTree):
    alias Game = Self.G

    @staticmethod
    fn name() -> StaticString:
        return "Principal Variation Negamax"

    fn search(mut self, game: Self.G, duration_ms: UInt) -> MoveScore[Self.G.Move]:
        var roots = [PrincipalVariationNode(move) for move in game.moves()]
        # var best_move = roots[0].move
        var logger = Logger(prefix="pvs2: ")
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        while True:
            sort[Self.greater](roots)
            ref first_root = roots[0]
            best_move = first_root.move
            logger.debug("--depth-", depth, best_move, " time ", (deadline - perf_counter_ns()) / 1_000_000_000)
            if first_root.move.score.is_loss() or first_root.move.score.is_win():
                return MoveScore[Self.G.Move](first_root.move.move, first_root.move.score)

            var g = game.copy()
            _ = g.play_move(first_root.move.move)
            var alpha = first_root._search(g, Score.loss(), Score.win(), 1, depth, deadline, logger)
            if not alpha.is_set():
                return best_move

            for i in range(1, len(roots)):
                ref root = roots[i]
                g = game.copy()
                _ = g.play_move(first_root.move.move)
                var score = root._search(g, alpha, alpha, 1, depth, deadline, logger)
                if not alpha.is_set():
                    return best_move
                elif score > alpha:
                    best_move = root.move
                    logger.debug("--depth-", depth, best_move, " time ", (deadline - perf_counter_ns()) / 1_000_000_000)
                    alpha = score
                    score = root._search(g, alpha, Score.win(), 1, depth, deadline, logger)
                    if not alpha.is_set():
                        return best_move
                    alpha = max(alpha, score)

            depth += 1

    @staticmethod
    @parameter
    fn greater(a: PrincipalVariationNode[Self.G], b: PrincipalVariationNode[Self.G]) -> Bool:
        return a.move.score > b.move.score


struct PrincipalVariationNode[G: TGame](Copyable, Movable, Writable):
    var move: MoveScore[Self.G.Move]
    var children: List[Self]

    fn __init__(out self, move: MoveScore[Self.G.Move]):
        self.move = move
        self.children = List[Self]()

    fn _search(mut self, game: Self.G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt, logger: Logger) -> Score:
        if perf_counter_ns() > deadline:
            return Score()

        if not self.children:
            var moves = game.moves()
            self.children = List[Self](capacity=len(moves))
            for move in moves:
                self.children.append(Self(move))

        var best_score = Score.loss()
        if depth == max_depth:
            for child in self.children:
                best_score = max(best_score, child.move.score)
            return best_score

        sort[Self.greater](self.children)

        if depth <= trace_level:
            logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        for ref child in self.children:
            if not child.move.score.is_decisive():
                child.move.score = Score()

        var idx = 0
        var state = first_move
        var g = game.copy()
        while idx < len(self.children):
            ref child = self.children[idx]
            if child.move.score.is_decisive():
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " = decisive-move: ", child.move, " ", child.move.score, " [", alpha, ":", beta, "]", sep="")
                if child.move.score > beta or child.move.score.is_win():
                    if depth <= trace_level:
                        logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                    return child.move.score

                alpha = max(alpha, child.move.score)
                idx += 1
                continue

            if state == zero_window:
                g = game.copy()

            if state != full_window:
                _ = g.play_move(child.move.move)

            var b = beta
            if state == zero_window:
                b = alpha
            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " > move: ", child.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, sep="")

            var score = -child._search(g, -b, -alpha, depth + 1, max_depth, deadline, logger)
            # if depth == 0:
            #     logger.debug("     move", child.move, child.move.score, " [", alpha, ":", b, "] time ", (deadline - perf_counter_ns()) / 1_000_000_000)

            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " < move: ", child.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, "; score: ", child.move.score, sep="")

            if not score.is_set():
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " << search: timeout", sep="")
                return Score()

            child.move.score = score

            if depth == 0 and child.move.score > best_score:
                best_move = MoveScore(child.move.move, child.move.score)
                logger.debug("best move", best_move, " [", alpha, ":", b, "] time ", (deadline - perf_counter_ns()) / 1_000_000_000)

            if child.move.score < alpha:
                state = zero_window
                idx = idx + 1
            elif child.move.score <= beta and child.move.score < Score.win():
                if state == zero_window and child.move.score > alpha:
                    state = full_window
                else:
                    state = zero_window
                    idx = idx + 1
                alpha = child.move.score
            else:
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " << search: cut-score: ", child.move.score, sep="")
                return child.move.score
            best_score = max(best_score, child.move.score)

        if depth <= trace_level:
            logger.trace("|  " * depth, depth, " << search: score: ", best_score, sep="")
        return best_score

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, depth=0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self.move.move, " ", self.move.score, "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_to(writer, depth + 1)

    @staticmethod
    @parameter
    fn greater(a: Self, b: Self) -> Bool:
        return a.move.score > b.move.score
