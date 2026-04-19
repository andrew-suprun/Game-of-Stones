from std.sys.defines import get_defined_string

from std.memory import Pointer
from std.time import perf_counter_ns
from std.math import sqrt, log
from std.logger import Logger

from traits import TTree, TGame, Score

comptime assert_mode = get_defined_string["ASSERT", "none"]()


struct Mcts[G: TGame, c: Float64](TTree):
    comptime Game = Self.G
    comptime MctsNode = Node[Self.G, Self.c]

    var root: Self.MctsNode
    var logger: Logger[]

    def __init__(out self):
        self.root = {{}}
        self.logger = Logger(prefix="mcts: ")

    def search(mut self, game: Self.G, max_time_ms: UInt) -> Self.G.Move:
        var moves = game.moves()
        assert len(moves) > 0
        if len(moves) == 1:
            return moves[0]
        var all_draws = True
        for move in moves:
            if move.is_decisive() and move.score() > 0:
                return move
            if not move.is_decisive() or move.score() != 0:
                all_draws = False
        if all_draws:
            return moves[0]
        self.root = {{}}
        var deadline = perf_counter_ns() + max_time_ms * 1_000_000
        while perf_counter_ns() < deadline:
            if self.expand(game):
                break

        return self._best_child()

    def expand(mut self, game: Self.G, out done: Bool):
        if self.root.move.is_decisive():
            return True

        var g = game.copy()
        self.root._expand(g)

        if self.root.move.is_decisive():
            return True

        var undecided = 0
        for ref child in self.root.children:
            if not child.move.is_decisive():
                undecided += 1
        return undecided < 2

    def best_move(self) -> Self.G.Move:
        return self._best_child()

    def _best_child(self) -> Self.G.Move:
        assert len(self.root.children) > 0
        var has_draw = False
        var last_idx = len(self.root.children)-1
        var draw_node = Pointer(to=self.root.children[last_idx])
        var best_child = Pointer(to=self.root.children[last_idx])
        for ref child in self.root.children:
            if child.move.is_decisive():
                if child.move.score() < 0:
                    continue
                elif child.move.score() > 0:
                    return child.move
                elif child.move.score() == 0:
                    has_draw = True
                    draw_node = Pointer(to=child)
                    continue

            if best_child[].n_sims < child.n_sims or best_child[].n_sims == child.n_sims and best_child[].move.score() < child.move.score():
                best_child = Pointer(to=child)
        if has_draw and best_child[].move.score() < 0:
            return draw_node[].move
        return best_child[].move

    def write_to[W: Writer](self, mut writer: W):
        for ref root in self.root.children:
            root.write_to(writer)

    def debug_roots(self) -> String:
        var result = "roots:\n"
        for ref node in self.root.children:
            result.write("  ", node.move, " sims ", node.n_sims, "\n")
        return result


struct Node[G: TGame, c: Float64](Copyable, Movable, Writable):
    var move: Self.G.Move
    var children: List[Self]
    var n_sims: Int32

    def __init__(out self):
        self = {{}}

    def __init__(out self, move: Self.G.Move):
        self.move = move
        self.children = {}
        self.n_sims = 1

    def _expand(mut self, mut game: Self.G):
        if not self.children:
            var moves = game.moves()

            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Self(move))
        else:
            ref selected_child = self.children[self.select_node()]
            game.play_move(selected_child.move)
            selected_child._expand(game)

        comptime if assert_mode == "all":
            assert len(self.children) > 0
            for child in self.children:
                assert (child.move.score() > -Self.G.Win and child.move.score() < Self.G.Win) ^ child.move.is_decisive()

        self.n_sims += 1
        var max_score = Score.MIN
        var all_decisive = True
        for ref child in self.children:
            max_score = max(max_score, child.move.score())
            if child.move.is_decisive():
                if child.move.score() > 0:
                    assert child.move.score() >= Self.G.Win
                    self.move.set_decisive()
            else:
                all_decisive = False
        self.move.set_score(-max_score)
        if all_decisive:
            self.move.set_decisive()
        assert (self.move.score() > -Self.G.Win and self.move.score() < Self.G.Win) ^ self.move.is_decisive()



    def select_node(self) -> Int:
        assert len(self.children) > 0
        var selected_child_idx = -1
        var max_v = Float64.MIN
        var log_n = log(Float64(self.n_sims))
        for child_idx in range(len(self.children)):
            ref child = self.children[child_idx]
            if child.move.is_decisive():
                continue
            var v = Float64(child.move.score()) + Self.c * sqrt(log_n/Float64(child.n_sims))
            if max_v < v:
                max_v = v
                selected_child_idx = child_idx
        assert selected_child_idx >= 0
        return selected_child_idx

    def write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0)

    def write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write(depth, ": ", "|   " * depth, self.move, " sims: ", self.n_sims, "\n")
        if self.children:  # unnecessary check to silence LSP warning
            for child in self.children:
                child.write_to(writer, depth + 1)
