from math import log2, sqrt
from utils.numerics import nan, inf, neg_inf


import game
from value import is_decisive, is_win, is_loss, is_draw, loss


@value
struct Node[Game: game.Game](CollectionElement):
    var move: Game.Move
    var value: Float32
    var first_child: Int32
    var last_child: Int32
    var n_sims: Int32

    fn __init__(out self, move: Game.Move, value: Float32):
        self.move = move
        self.value = value
        self.first_child = -1
        self.last_child = -1
        self.n_sims = 1


struct Tree[Game: game.Game](Stringable, Writable):
    var c: Float32
    var nodes: List[Node[Game]]
    var top_moves: List[Game.Move]
    var top_values: List[Float32]

    fn __init__(out self, c: Float32):
        self.c = c
        self.nodes = List[Node[Game]]()
        self.top_moves = List[Game.Move]()
        self.top_values = List[Float32]()

    fn expand(mut self, game: Game):
        print("expand")
        if not is_decisive(self.nodes[0].value):
            var game_copy = game.copy()
            self._expand(game_copy, 0)
            self._validate()

    fn _expand(mut self, mut game: Game, parent_idx: Int32):
        var parent = self.nodes[parent_idx]
        var first_child = parent.first_child
        var last_child = parent.last_child
        var children = range(first_child, last_child)
        if first_child == 0:
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
            debug_assert(selected_child_idx > 1, "Failed to select a child.")
            game.play_move(self.nodes[selected_child_idx].move)
            self._expand(game, selected_child_idx)

        self.nodes[parent_idx].n_sims = 0
        self.nodes[parent_idx].value = loss()
        var has_draw = False
        for i in children:
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
        if has_draw and parent.value < 0:
            parent.value = 0

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        pass

    fn _validate(self):
        pass
