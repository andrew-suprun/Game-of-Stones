from std.time import perf_counter_ns

from .config import Assert, Debug, Trace
from .traits import TTree, TGame, Score


struct PrincipalVariationNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: PrincipalVariationNode[Self.G]

    def __init__(out self):
        self.root = {{}, Score.loss(), {}}

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        self.root = {{}, Score.loss(), {}}
        var depth = 1
        var start = perf_counter_ns()
        var deadline = start + UInt(1_000_000) * max_time_ms
        while True:
            self.root.search(game, Score.loss(), Score.win(), 0, depth, deadline)
            var pv = self._pv()
            if perf_counter_ns() > deadline:
                return pv^

            var time = Float64(perf_counter_ns() - start) / 1_000_000_000
            comptime if Debug:
                print(t"    pvs: depth: {depth}, score: {-game.score()}, time: {time},  pv: {pv}")
            if self.root.score.is_decisive():
                return pv^

            var n_non_loosing_moves = 0
            for child in self.root.children:
                if child.score.is_decisive():
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


struct PrincipalVariationNode[G: TGame](Copyable, Writable):
    var move: Self.G.Move
    var score: Score
    var max_depth: Int
    var children: List[Self]

    def __init__(out self, move: Self.G.Move, score: Score, max_depth: Int):
        self.move = move
        self.score = score
        self.max_depth = max_depth
        self.children = List[Self]()

    def search(
        mut self,
        game: Self.G,
        var alpha: Score,
        beta: Score,
        depth: Int,
        max_depth: Int,
        deadline: UInt,
    ):
        if perf_counter_ns() > deadline:
            return

        if not self.children:
            self.children = [Self(mv.move, mv.score, max_depth) for mv in game.top_moves()]

        self.max_depth = max_depth
        self.score = Score.win()

        if depth == max_depth:
            self._update_score()
            return

        sort[Self.gt](self.children)

        var idx = 0
        var zero_window = False
        while idx < len(self.children):
            ref child = self.children[idx]

            var new_beta = alpha if zero_window else beta

            if not child.score.is_decisive():
                var g = game.copy()
                g.play_move(child.move)

                var start = perf_counter_ns()
                var window = "zero" if zero_window else "full"
                comptime if Trace:
                    if depth < 2:
                        print(t"[{depth}] {'    '*depth}  >> child={child.move} [{alpha} : {new_beta}] {window} window")

                child.search(g, -new_beta, -alpha, depth + 1, max_depth, deadline)

                comptime if Trace:
                    if depth < 2:
                        print(t"[{depth}] {'    '*depth}  << child={child.move} {child.score} time: {(perf_counter_ns() - start) / 10_000} {window} window")

            comptime if Trace:
                print(t"[{depth}] {'    '*depth}  -- self={self.move} {child.score}")

            var child_score = child.score if not child.score.is_draw() else Score(0)
            alpha = max(alpha, child_score)
            if alpha > new_beta or alpha.is_win():
                if zero_window:
                    zero_window = False
                    comptime if Trace:
                        print(t"[{depth}] {'    '*depth}  -- retest with full window")
                    continue
                else:
                    comptime if Trace:
                        print(t"[{depth}] {'    '*depth}  -- beta cut")
                    self._update_score()
                    return

            idx += 1
            if child_score > alpha:
                alpha = child_score
                zero_window = True
                comptime if Trace:
                    print(t"[{depth}] {'    '*depth}  -- new alpha={alpha} use zero window next")
            else:
                comptime if Trace:
                    var window = "zero" if zero_window else "full"
                    print(t"[{depth}] {'    '*depth}  --  keep using {window} window next")

        self._update_score()

    def _update_score(mut self):
        var best_score = Score.loss()
        var has_draw = False
        var all_decisive = True
        for child in self.children:
            if child.score.is_win():
                self.score = Score.loss()
                return
            elif child.score.is_loss():
                continue
            elif child.score.is_draw():
                has_draw = True
            else:
                all_decisive = False
                best_score = max(best_score, child.score)
        if has_draw and all_decisive:
            self.score = Score.draw()
        else:
            self.score = -best_score

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
            ref best_child = self.children[best_child_idx]
            if Self.gt(child, best_child):
                best_child_idx = idx

        return self.children[best_child_idx]

    def sort(mut self):
        if self.children:  # TODO silence the compiler warning
            for ref child in self.children:
                child.sort()
        sort[Self.gt](self.children)

    def write_to[W: Writer](self, mut writer: W):
        writer.write(t"{self.move} {self.score}")

    def write_repr_to[W: Writer](self, mut writer: W):
        self.write_repr_to(writer, depth=0)

    def write_repr_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, "[", depth, "] ", self.move, " ", self.score, "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_repr_to(writer, depth + 1)

    @staticmethod
    @parameter
    def gt(a: Self, b: Self) -> Bool:
        if a.max_depth > b.max_depth:
            return True
        elif a.max_depth < b.max_depth:
            return False
        else:
            return a.score > b.score
