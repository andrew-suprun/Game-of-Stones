from std.time import perf_counter_ns
from std.logger import Logger

from traits import TTree, TGame, Score


struct AlphaBetaNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: AlphaBetaNode[Self.G]
    var logger: Logger[]

    def __init__(out self):
        self.root = AlphaBetaNode[Self.G]({})
        self.logger = Logger(prefix="abs3: ")

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * max_time_ms
        var start = perf_counter_ns()
        while True:
            var _, done = self.root._search(game, -Self.G.Win, Self.G.Win, 0, depth, deadline, self.logger)
            if done:
                return self._pv()

            var time = Float64(perf_counter_ns() - start) / 1_000_000_000
            self.logger.trace("=== max depth: ", depth, " move:", repr(self._pv()[0]), " time:", time)
            depth += 1

    def _pv(self) -> List[Self.G.Move]:
        var pv = List[Self.G.Move]()
        self.root._pv(pv)
        return pv^


struct AlphaBetaNode[G: TGame](Copyable, Writable):
    var move: Self.G.Move
    var children: List[Self]

    def __init__(out self, move: Self.G.Move):
        self.move = move
        self.children = List[Self]()

    def _search(
        mut self,
        game: Self.G,
        var alpha: Score,
        beta: Score,
        depth: Int,
        max_depth: Int,
        deadline: UInt,
        logger: Logger,
    ) -> Tuple[Score, Bool]:
        if perf_counter_ns() > deadline:
            return (-Self.G.Win, True)

        if not self.children:
            var moves = game.moves()
            assert len(moves) > 0
            self.children = [Self(move) for move in moves]

        var best_score = -Self.G.Win
        if depth == max_depth:
            for child in self.children:
                best_score = max(best_score, child.move.score())
            return (best_score, False)

        sort[Self.greater](self.children)

        for ref child in self.children[1:]:
            if not child.move.is_decisive():
                child.move.set_score(-Self.G.Win)

        for ref child in self.children:
            var g = game.copy()
            if not child.move.is_decisive():
                g.play_move(child.move)
                var score, done = child._search(g, -beta, -alpha, depth + 1, max_depth, deadline, logger)
                if done:
                    return (best_score, True)
                else:
                    child.move.set_score(-score)

            if child.move.score() > best_score:
                best_score = child.move.score()

            if best_score >= beta or best_score == Self.G.Win:
                return (best_score, False)

            alpha = max(alpha, child.move.score())

        return (best_score, False)

    def _pv(self, mut pv: List[Self.G.Move]):
        if not self.children:
            return

        ref best_child = self._best_node()
        pv.append(best_child.move)
        best_child._pv(pv)

    def _best_node(self) -> ref[self.children] Self:
        var best_child_idx = 0
        for idx in range(len(self.children)):
            ref child = self.children[idx]
            if child.move.is_decisive():
                if child.move.score() < 0:
                    continue
                elif child.move.score() > 0:
                    return child

            if self.children[best_child_idx].move.score() < child.move.score():
                best_child_idx = idx

        return self.children[best_child_idx]

    def write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, depth=0)

    def write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self.move, " ", self.move.score(), "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_to(writer, depth + 1)

    @staticmethod
    @parameter
    def greater(a: Self, b: Self) -> Bool:
        return a.move.score() > b.move.score()
