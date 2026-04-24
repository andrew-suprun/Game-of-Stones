from std.time import perf_counter_ns
from std.logger import Logger

from traits import TTree, TGame, Score


struct AlphaBetaNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: AlphaBetaNode[Self.G]
    var logger: Logger[]

    @staticmethod
    def name() -> StaticString:
        return "Alpha-Beta Negamax With Memory"

    def __init__(out self):
        self.root = AlphaBetaNode[Self.G]({})
        self.logger = Logger(prefix="abs: ")

    def search(mut self, game: Self.Game, max_time_ms: UInt, out pv: List[Self.Game.Move]):
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * max_time_ms
        var start = perf_counter_ns()
        while True:
            print("@1")
            var best_move = self.root._search(game, Score.MIN, Score.MAX, 0, depth, deadline, self.logger)
            print("@2", repr(best_move))
            # TODO return best_move all other children are losing
            if perf_counter_ns() > deadline:
                print("@3")
                return self._pv()

            self.logger.debug("=== max depth: ", depth, " move:", best_move, " time:", Float64(perf_counter_ns() - start) / 1_000_000_000)
            if best_move.is_decisive():
                print("@4", repr(best_move))
                return self._pv()

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

    def _search(mut self, game: Self.G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt, logger: Logger, out best_move: Self.G.Move):
        print("#1", depth)
        if not self.children:
            self.children = [Self(move) for move in game.moves()]

        print("#2")
        best_move = self.children[0].move
        print("#3")

        if perf_counter_ns() > deadline:
            return

        print("#4")
        if depth == max_depth:
            for child in self.children:
                if best_move < child.move:
                    best_move = child.move
            print("#5")
            return

        sort[Self.greater](self.children)

        for ref child in self.children:
            if not child.move.is_decisive():
                child.move.set_score(Score.MIN)

        for ref child in self.children:
            var g = game.copy()
            if not child.move.is_decisive():
                _ = g.play_move(child.move)
                var deeper_best_move = child._search(g, -beta, -alpha, depth + 1, max_depth, deadline, logger)
                child.move.set_score(-deeper_best_move.score())

            if child.move.score() > best_move.score():
                best_move = child.move

            if best_move.score() > beta or best_move.is_win():
                print("#6")
                return

            alpha = max(alpha, child.move.score())

        print("#7")

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
        writer.write("|   " * depth, repr(self.move), "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_to(writer, depth + 1)

    @staticmethod
    @parameter
    def greater(a: Self, b: Self) -> Bool:
        return a.move > b.move