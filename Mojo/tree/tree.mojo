from math import log2, sqrt


import game
from value import is_decisive, is_win, is_loss, is_draw, win, loss


@value
struct Node(CollectionElement, Stringable, Writable):
    var move: game.Move
    var value: Float32
    var first_child: Int32
    var last_child: Int32
    var n_sims: Int32

    fn __init__(out self, move: game.Move, value: Float32):
        self.move = move
        self.value = value
        self.first_child = -1
        self.last_child = -1
        self.n_sims = 1

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.move, " v: ", self.value)


struct Tree[Game: game.Game](Stringable, Writable):
    var c: Float32
    var nodes: List[Node]
    var top_moves: List[game.Move]
    var top_values: List[Float32]

    fn __init__(out self, c: Float32):
        self.c = c
        self.nodes = List[Node](Node(game.Move(0, 0, 0, 0), 0))
        self.top_moves = List[game.Move]()
        self.top_values = List[Float32]()

    fn expand(mut self, game: Game):
        if not is_decisive(self.nodes[0].value):
            var game_copy = game.copy()
            self._expand(game_copy, 0)

    fn _expand(mut self, mut game: Game, parent_idx: Int32):
        var parent = self.nodes[parent_idx]
        var first_child = parent.first_child
        var last_child = parent.last_child
        var children = range(first_child, last_child)
        if first_child == -1:
            game.top_moves(self.top_moves, self.top_values)
            debug_assert(
                self.top_moves.size > 0,
                "Function game.top_moves(...) returns empty result.",
            )

            self.nodes[parent_idx].first_child = Int32(self.nodes.size)
            for idx in range(self.top_moves.size):
                self.nodes.append(
                    Node(self.top_moves[idx], self.top_values[idx])
                )
            self.nodes[parent_idx].last_child = Int32(self.nodes.size)
        else:
            var selected_child_idx = Int32(-1)
            var n_sims = Float32(parent.n_sims)
            var log_parent_sims = log2(n_sims)
            var maxV = loss()
            for idx in children:
                var child = self.nodes[idx]
                if is_decisive(child.value):
                    continue
                var v = child.value / n_sims + self.c * sqrt(
                    log_parent_sims / Float32(child.n_sims)
                )
                if v > maxV:
                    maxV = v
                    selected_child_idx = idx
            debug_assert(selected_child_idx > 0, "Failed to select a child.")
            game.play_move(self.nodes[selected_child_idx].move)
            self._expand(game, selected_child_idx)

        self.nodes[parent_idx].n_sims = 0
        self.nodes[parent_idx].value = win()
        var has_draw = False
        for i in range(
            self.nodes[parent_idx].first_child,
            self.nodes[parent_idx].last_child,
        ):
            var child = self.nodes[i]
            if is_win(child.value):
                self.nodes[parent_idx].value = -child.value
                return
            elif is_draw(child.value):
                has_draw = True
                continue
            elif is_loss(child.value):
                continue
            self.nodes[parent_idx].n_sims += child.n_sims
            if self.nodes[parent_idx].value >= -child.value:
                self.nodes[parent_idx].value = -child.value
        if has_draw and self.nodes[parent_idx].value > 0:
            self.nodes[parent_idx].value = 0

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0, 0)

    fn write_to[W: Writer](self, mut writer: W, idx: Int32, depth: Int):
        writer.write("|   " * depth, self.nodes[idx], "\n")
        var parent = self.nodes[idx]
        if parent.first_child != -1:
            for child_idx in range(parent.first_child, parent.last_child):
                self.write_to(writer, child_idx, depth + 1)
