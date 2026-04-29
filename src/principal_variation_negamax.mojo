from std.time import perf_counter_ns

from config import Assert, Debug, Trace
from score import Score, Win, Loss
from traits import TTree, TGame


struct PrincipalVariationNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: PrincipalVariationNode[Self.G]

    def __init__(out self):
        self.root = {{}, {}}

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        var depth = 1
        var start = perf_counter_ns()
        var deadline = start + UInt(1_000_000) * max_time_ms
        while True:
            self.root.search(game, Loss, Win, 0, depth, deadline)
            var pv = self._pv()
            if perf_counter_ns() > deadline:
                return pv^

            var time = Float64(perf_counter_ns() - start) / 1_000_000_000
            comptime if Debug:
                print(t"    pvs: dpth: {depth}, score: {pv[0].score()}, time: {time},  pv: {pv}")
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


struct PrincipalVariationNode[G: TGame](Copyable, Writable):
    var move: Self.G.Move
    var max_depth: Int
    var children: List[Self]

    def __init__(out self, move: Self.G.Move, max_depth: Int):
        self.move = move
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
            self.children = [Self(move, max_depth) for move in game.moves()]

        self.max_depth = max_depth
        self.move.set_score(Win)

        if depth == max_depth:
            for child in self.children:
                self.move.set_score(Score.min(self.move.score(), -child.move.score()))
            return

        sort[Self.greater](self.children)

        var idx = 0
        var zero_window = False
        while idx < len(self.children):
            ref child = self.children[idx]

            var new_beta = alpha if zero_window else beta

            comptime if Trace:
                var window = "zero" if zero_window else "full"
                print(t"[{depth}] {"    "*depth}  >> child={child.move} [{alpha} : {new_beta}] {window} window")

            if not child.move.score().is_decisive():
                var g = game.copy()
                g.play_move(child.move)

                child.search(g, -new_beta, -alpha, depth + 1, max_depth, deadline)

            comptime if Trace:
                print(t"[{depth}] {"    "*depth}  << child={repr(child.move)}")

            self.move.set_score(Score.min(self.move.score(), -child.move.score()))

            comptime if Trace:
                print(t"[{depth}] {"    "*depth}  -- self={repr(self.move)}")

            if child.move.score() >= new_beta:
                if zero_window:
                    zero_window = False
                    alpha = child.move.score()
                    comptime if Trace:
                        print(t"[{depth}] {"    "*depth}  -- retest with full window")
                    continue
                else:
                    comptime if Trace:
                        print(t"[{depth}] {"    "*depth}  -- beta cut")
                    return

            idx += 1
            if child.move.score() > alpha:
                alpha = child.move.score()
                zero_window = True
                comptime if Trace:
                    print(t"[{depth}] {"    "*depth}  -- new alpha={alpha} use zero window next")
            else:
                comptime if Trace:
                    var window = "zero" if zero_window else "full"
                    print(t"[{depth}] {"    "*depth}  --  keep using {window} window next")

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
            if Self.greater(child, best_child):
                best_child_idx = idx

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
        if a.max_depth > b.max_depth:
            return True
        elif a.max_depth < b.max_depth:
            return False
        else:
            return a.move.score() > b.move.score()
