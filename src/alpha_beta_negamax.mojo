from std.time import perf_counter_ns

from config import Debug
from score import Score, Win, Loss, Draw
from traits import TTree, TGame


struct AlphaBetaNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: AlphaBetaNode[Self.G]

    def __init__(out self):
        self.root = {{}, {}}

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        var depth = 1
        var start = perf_counter_ns()
        var deadline = start + UInt(1_000_000) * max_time_ms
        while True:
            self.root._search(game, Loss, Win, 0, depth, deadline)
            var pv = self._pv()
            if perf_counter_ns() > deadline:
                return pv^

            var time = Float64(perf_counter_ns() - start) / 1_000_000_000
            comptime if Debug:
                print(t"=== max depth: {depth}, score: {pv[0].score()}, time: {time},  pv: {pv}")
            if pv[0].score().is_decisive():
                return pv^

            var n_non_loosing_moves = 0
            for child in self.root.children:
                if not child.move.score().is_decisive():
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
    var max_depth: Int
    var children: List[Self]

    def __init__(out self, move: Self.G.Move, max_depth: Int):
        self.move = move
        self.max_depth = max_depth
        self.children = List[Self]()

    def _search(
        mut self,
        game: Self.G,
        var alpha: Score,
        beta: Score,
        depth: Int,
        max_depth: Int,
        deadline: UInt,
    ):
        if not self.children:
            self.children = [Self(move, max_depth) for move in game.moves()]

        if depth == max_depth:
            self._update_score()
            self.max_depth = max_depth
            return

        sort[Self.greater](self.children)

        for ref child in self.children:
            var g = game.copy()
            if not child.move.score().is_decisive():
                g.play_move(child.move)
                child._search(g, -beta, -alpha, depth + 1, max_depth, deadline)
                if perf_counter_ns() > deadline:
                    return

            alpha = max(alpha, child.move.score())
            if alpha >= beta or alpha.is_win():
                break

        self._update_score()
        self.max_depth = max_depth

    def _update_score(mut self):
        var best_score = Loss
        for ref child in self.children:
            best_score = Score.max(best_score, child.move.score())

        self.move.set_score(-best_score)

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
            if score.is_loss():
                continue
            elif score.is_win():
                return child
            elif score.is_draw():
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
        writer.write("|   " * depth, repr(self.move), " [", self.max_depth, "]\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_repr_to(writer, depth + 1)

    @staticmethod
    @parameter
    def greater(a: Self, b: Self) -> Bool:
        if a.max_depth > b.max_depth:
            return True
        elif a.max_depth < b.max_depth:
            return False
        else:
            return a.move.score() > b.move.score()
