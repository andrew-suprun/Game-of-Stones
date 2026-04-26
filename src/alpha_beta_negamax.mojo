from std.time import perf_counter_ns
from std.logger import Logger

from score import Score, NoScore, Draw, is_set, is_win, is_loss, is_draw, is_decisive
from traits import TTree, TGame


struct AlphaBetaNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: AlphaBetaNode[Self.G]
    var logger: Logger[]

    def __init__(out self):
        self.root = AlphaBetaNode[Self.G]({})
        self.logger = Logger(prefix="abs: ")

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        var depth = 1
        var start = perf_counter_ns()
        var deadline = start + UInt(1_000_000) * max_time_ms
        while True:
            var score = self.root._search(game, Score.MIN, Score.MAX, 0, depth, deadline, self.logger)
            var pv = self._pv()
            if not is_set(score):
                return pv^

            var time = Float64(perf_counter_ns() - start) / 1_000_000_000
            self.logger.debug(t"=== max depth: {depth}, score: {pv[0].score()}, time: {time},  pv: {pv}")
            if is_decisive(pv[0].score()):
                return pv^

            var n_non_loosing_moves = 0
            for child in self.root.children:
                if not is_decisive(child.move.score()):
                    n_non_loosing_moves += 1

            if n_non_loosing_moves == 1:
                return pv^

            depth += 1

    def _pv(self) -> List[Self.G.Move]:
        var pv = List[Self.G.Move]()
        self.root._pv(pv)
        return pv^

    def write_repr_to[W: Writer](self, mut writer: W):
        self.root.write_repr_to(writer)


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
    ) -> Score:
        if perf_counter_ns() > deadline:
            return NoScore

        if not self.children:
            self.children = [Self(move) for move in game.moves()]

        var best_score = Score.MIN
        if depth == max_depth:
            for child in self.children:
                best_score = max(best_score, child.move.score())
            return best_score

        sort[Self.greater](self.children)

        for ref child in self.children[1:]:
            if not is_decisive(child.move.score()):
                child.move.set_score(NoScore)

        for ref child in self.children:
            var g = game.copy()
            if not is_decisive(child.move.score()):
                g.play_move(child.move)
                var score = child._search(g, -beta, -alpha, depth + 1, max_depth, deadline, logger)
                if not is_set(score):
                    return NoScore
                elif is_draw(score):
                    child.move.set_score(Draw)
                elif score == 0:
                    child.move.set_score(0)
                else:
                    child.move.set_score(-score)

            if child.move.score() > best_score:
                best_score = child.move.score()

            if best_score > beta or is_win(best_score):
                return best_score

            alpha = max(alpha, best_score)

        return best_score

    def _pv(self, mut pv: List[Self.G.Move]):
        if not self.children:
            return

        ref best_child = self._best_node()
        pv.append(best_child.move)
        best_child._pv(pv)

    def _best_node(self) -> ref[self.children] Self:
        var has_draw = False
        var draw_node_idx = len(self.children) - 1
        var best_child_idx = 0
        for idx in range(len(self.children)):
            ref child = self.children[idx]
            var score = child.move.score()
            if is_loss(score) or not is_set(score):
                continue
            elif is_win(score):
                return child
            elif is_draw(score):
                has_draw = True
                draw_node_idx = idx
                continue

            ref best_child = self.children[best_child_idx]
            if best_child.move.score() < score:
                best_child_idx = idx

        if has_draw and self.children[best_child_idx].move.score() < 0:
            return self.children[draw_node_idx]

        return self.children[best_child_idx]

    def write_repr_to[W: Writer](self, mut writer: W):
        self.write_repr_to(writer, depth=0)

    def write_repr_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, repr(self.move), "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_repr_to(writer, depth + 1)

    @staticmethod
    @parameter
    def greater(a: Self, b: Self) -> Bool:
        return a.move.score() > b.move.score()
