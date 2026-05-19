from std.time import perf_counter_ns

from config import Debug, Trace
from value import Value, Win, Loss, Draw, is_win, is_loss, is_draw, is_decisive, value_str
from traits import TTree, TGame


struct AlphaBetaNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: AlphaBetaNode[Self.G]

    def __init__(out self):
        self.root = {{}, Loss, {}}

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
                print(t"    abs: depth: {depth}, value: {value_str(-self.root.value)}, time: {time},  pv: {pv}")

            if is_decisive(self.root.value):
                return pv^

            var n_non_loosing_moves = 0
            for child in self.root.children:
                if not is_decisive(child.value):
                    n_non_loosing_moves += 1

            if n_non_loosing_moves == 1:
                return pv^

            depth += 1

    def value(self) -> Value:
        return self.root.value

    def _pv(self) -> List[Self.G.Move]:
        var pv = List[Self.G.Move]()
        self.root._pv(pv)
        return pv^

    def write_repr_to[W: Writer](self, mut writer: W):
        self.root.write_repr_to(writer)


struct AlphaBetaNode[G: TGame](Copyable, Writable):
    var move: Self.G.Move
    var value: Value
    var max_depth: Int
    var children: List[Self]

    def __init__(out self, move: Self.G.Move, value: Value, max_depth: Int):
        self.move = move
        self.value = value
        self.max_depth = max_depth
        self.children = List[Self]()

    def search(
        mut self,
        game: Self.G,
        var alpha: Value,
        beta: Value,
        depth: Int,
        max_depth: Int,
        deadline: UInt,
    ):
        if perf_counter_ns() > deadline:
            return

        if not self.children:
            self.children = [Self(mv.move, mv.value, max_depth) for mv in game.moves()]

        self.max_depth = max_depth
        self.value = Win

        if depth == max_depth:
            self._update_value()
            return

        sort[Self.gt](self.children)

        for ref child in self.children:
            if not is_decisive(child.value):
                var g = game.copy()
                g.play_move(child.move)

                var start = perf_counter_ns()
                comptime if Trace:
                    if depth < 2:
                        print(t"[{depth}] {'    '*depth}  >> child={child.move} [{alpha} : {beta}]")

                child.search(g, -beta, -alpha, depth + 1, max_depth, deadline)

                comptime if Trace:
                    if depth < 2:
                        print(
                            t"[{depth}] {'    '*depth}  << child={child.move} {value_str(child.value)}; time:"
                            t" {(perf_counter_ns() - start) / 10_000}"
                        )

            var child_value = child.value if not is_draw(child.value) else 0
            alpha = max(alpha, child_value)
            if alpha > beta or is_win(alpha):
                break

        self._update_value()

    def _update_value(mut self):
        var best_value = Loss
        var has_draw = False
        var all_decisive = True
        for child in self.children:
            if is_win(child.value):
                self.value = Loss
                return
            elif is_loss(child.value):
                continue
            elif is_draw(child.value):
                has_draw = True
            else:
                all_decisive = False
                best_value = max(best_value, child.value)
        if has_draw and all_decisive:
            self.value = Draw
        else:
            self.value = -best_value

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
        writer.write(t"{self.move} {self.value}")

    def write_repr_to[W: Writer](self, mut writer: W):
        self.write_repr_to(writer, depth=0)

    def write_repr_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, "[", depth, "] ", self.move, " ", value_str(self.value), "\n")
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
            return a.value > b.value
