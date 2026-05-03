from std.time import perf_counter_ns

from score import Score, Loss
from traits import TTree, TGame, TMove


comptime Idx = UInt32

struct MctsNode[M: TMove](TrivialRegisterPassable, Writable):
    var move: Self.M
    var n_sims: UInt32
    var first_child: Idx
    var n_children: UInt32

    def __init__(out self):
        self = {{}}

    def __init__(out self, move: Self.M):
        self.move = move
        self.n_sims = 1
        self.first_child = 0
        self.n_children = 0

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.move)

    def write_repr_to[W: Writer](self, mut writer: W):
        writer.write(repr(self.move), " sims: ", self.n_sims, "\n")


struct Mcts[G: TGame, c: Float64](TTree):
    comptime Game = Self.G
    comptime Node = MctsNode[Self.G.Move]

    var tree: List[Self.Node]

    def __init__(out self):
        self.tree = [{}]

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        self.tree.clear()
        var deadline = perf_counter_ns() + max_time_ms * 1_000_000
        while perf_counter_ns() < deadline:
            self.expand(game)
            var n_undecisive = 0
            ref root = self.tree[0]
            for idx in range(root.first_child, root.first_child + root.n_children):
                ref child = self.tree[idx]
                if not child.move.score().is_decisive():
                    n_undecisive += 1
            if n_undecisive <= 1:
                break

        return self._pv()

    def expand(mut self, game: Self.G):
        var g = game.copy()
        var idx: Idx = 0
        var parent_indices: List[Idx] = [idx]
        while True:
            ref node = self.tree[idx]
            if node.n_children == 0:
                break
            idx = self._select_child_idx(idx)
            parent_indices.append(idx)
            ref child = self.tree[idx]
            g.play_move(child.move)


        var moves = g.moves()
        ref leaf = self.tree[idx]
        leaf.first_child = Idx(len(self.tree))
        leaf.n_children = UInt32(len(moves))
        self.tree.reserve(len(moves))
        for move in moves:
            self.tree.append(Self.Node(move))

        for parent_idx in reversed(parent_indices):
            ref parent = self.tree[parent_idx]
            parent.n_sims += 1
            var best_score = Loss
            for idx in range(parent.first_child, parent.first_child + parent.n_children):
                ref child = self.tree[idx]
                best_score = Score.max(best_score, child.move.score())

            parent.move.set_score(-best_score)

    def _select_child_idx(self, parent_idx: Idx) -> Idx:
        ref parent = self.tree[parent_idx]
        var selected_child_idx: Idx = Idx.MAX
        var max_v = Float64.MIN
        for child_idx in range(parent.first_child, parent.first_child + parent.n_children):
            ref child = self.tree[child_idx]
            if child.move.score().is_decisive():
                continue
            var v = Float64(child.move.score()) + Self.c * Float64(parent.n_sims) / Float64(child.n_sims)
            if max_v < v:
                max_v = v
                selected_child_idx = child_idx
        assert selected_child_idx != Idx.MAX
        return selected_child_idx

    def _pv(self) -> List[Self.G.Move]:
        var pv = List[Self.G.Move]()
        var idx: Idx = 0
        while True:
            ref node = self.tree[idx]
            if node.n_children == 0:
                return pv^
            idx = self._best_child_idx(idx)

    def _best_child_idx(self, parent_idx: Idx) -> Idx:
        ref parent = self.tree[parent_idx]
        var best_child_idx: Idx = 0
        for idx in range(parent.first_child, parent.first_child + parent.n_children):
            ref child = self.tree[idx]
            ref best_child = self.tree[best_child_idx]
            if child.move.score() > best_child.move.score():
                best_child_idx = idx

        return best_child_idx

    def write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0, 0)

    def write_to[W: Writer](self, mut writer: W, depth: Int, idx: Idx):
        ref node = self.tree[idx]
        writer.write(depth, ": ", "|   " * depth, repr(node), "\n")
        if depth >= 2:
            return

        for child_idx in range(node.first_child, node.first_child + node.n_children):
            self.write_to(writer, depth + 1, child_idx)

    def write_repr_to[W: Writer](self, mut writer: W):
        self.write_repr_to(writer, 0, 0)

    def write_repr_to[W: Writer](self, mut writer: W, depth: Int, idx: Idx):
        ref node = self.tree[idx]
        writer.write(depth, ": ", "|   " * depth, repr(node), "\n")

        if node.n_children > 0:
            for child_idx in range(node.first_child, node.first_child + node.n_children):
                self.write_repr_to(writer, depth + 1, child_idx)

    def debug_roots(self) -> String:
        ref root = self.tree[0]
        var result = "roots:\n"
        for idx in range(root.first_child, root.first_child + root.n_children):
            ref node = self.tree[idx]
            result.write("  ", node.move, " sims ", node.n_sims, "\n")
        return result
