from std.time import perf_counter_ns

from .value import Value, Draw, Loss, is_win, is_loss, is_draw, is_decisive
from .traits import TTree, TGame, TMove


comptime Idx = UInt32


struct MctsNode[M: TMove](TrivialRegisterPassable, Writable):
    var move: Self.M
    var value: Value
    var n_sims: UInt32
    var first_child: Idx
    var n_children: UInt32

    def __init__(out self):
        self = {{}, Loss}

    def __init__(out self, move: Self.M, value: Value):
        self.move = move
        self.value = value
        self.n_sims = 1
        self.first_child = 0
        self.n_children = 0

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.move, " ", self.value)

    def write_repr_to[W: Writer](self, mut writer: W):
        writer.write(self.move, " ", self.value, " sims: ", self.n_sims)


struct Mcts[G: TGame, c: Value](TTree):
    comptime Game = Self.G
    comptime Node = MctsNode[Self.G.Move]

    var tree: List[Self.Node]

    def __init__(out self):
        self.tree = [{}]

    def search(mut self, game: Self.G, max_moves: Int, max_time_ms: UInt) -> List[Self.G.Move]:
        self.tree.clear()
        self.tree.append({})
        var moves = List[MoveValue[Self.G.Move]](capacity=max_moves)

        var deadline = perf_counter_ns() + max_time_ms * 1_000_000
        while perf_counter_ns() < deadline:
            self.expand(game, max_moves, moves)
            var n_undecisive = 0
            ref root = self.tree[0]
            if is_loss(root.value):
                return self._pv()
            for idx in range(root.first_child, root.first_child + root.n_children):
                ref child = self.tree[idx]

                if not is_decisive(child.value):
                    n_undecisive += 1

            if n_undecisive <= 1:
                break

        return self._pv()

    def expand(mut self, game: Self.G, max_moves: Int, mut moves: List[MoveValue[Self.G.Move]]):
        var g = game.copy()
        var idx: Idx = 0
        var parent_indices: List[Idx] = [idx]
        var depth = 0
        while True:
            ref node = self.tree[idx]
            if node.n_children == 0:
                break
            idx = self._select_child_idx(idx)
            parent_indices.append(idx)
            ref child = self.tree[idx]
            g.play_move(child.move)
            depth += 1

        var leaf_max_moves = max(max_moves - depth, 8)
        g.top_moves(leaf_max_moves, moves)
        ref leaf = self.tree[idx]
        leaf.first_child = Idx(len(self.tree))
        leaf.n_children = UInt32(len(moves))
        for mv in moves:
            self.tree.append(Self.Node(mv.move, mv.value))

        for parent_idx in reversed(parent_indices):
            ref parent = self.tree[parent_idx]
            parent.n_sims += 1
            var best_value = Loss
            var has_draw = False
            var all_decisive = True
            for idx in range(parent.first_child, parent.first_child + parent.n_children):
                ref child = self.tree[idx]
                if is_win(child.value):
                    parent.value = Loss
                    break
                elif is_loss(child.value):
                    continue
                elif is_draw(child.value):
                    has_draw = True
                else:
                    all_decisive = False
                    best_value = max(best_value, child.value)
            else:
                if has_draw and all_decisive:
                    parent.value = Draw
                else:
                    parent.value = -best_value

    def value(self) -> Value:
        return self.tree[0].value

    def _select_child_idx(self, parent_idx: Idx) -> Idx:
        ref parent = self.tree[parent_idx]
        var selected_child_idx: Idx = Idx.MAX
        var max_v = Value.MIN
        for child_idx in range(parent.first_child, parent.first_child + parent.n_children):
            ref child = self.tree[child_idx]
            if is_decisive(child.value):
                continue
            var v = child.value + Self.c * Value(parent.n_sims) / Value(child.n_sims)
            if max_v < v:
                max_v = v
                selected_child_idx = child_idx
        assert selected_child_idx != Idx.MAX
        return selected_child_idx

    def _pv(self) -> List[Self.G.Move]:
        var pv = List[Self.G.Move]()
        var idx: Idx = 0
        while True:
            if self.tree[idx].n_children == 0:
                return pv^
            idx = self._best_child_idx(idx)
            pv.append(self.tree[idx].move)

    def _best_child_idx(self, parent_idx: Idx) -> Idx:
        ref parent = self.tree[parent_idx]
        var best_child_idx = parent.first_child
        for idx in range(parent.first_child, parent.first_child + parent.n_children):
            ref child = self.tree[idx]
            ref best_child = self.tree[best_child_idx]
            if child.value > best_child.value:
                best_child_idx = idx

        return best_child_idx

    def write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0, 0)

    def write_to[W: Writer](self, mut writer: W, depth: Int, idx: Idx):
        ref node = self.tree[idx]
        writer.write(depth, ": ", "|   " * depth, repr(node), "\n")
        if depth >= 1:
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
