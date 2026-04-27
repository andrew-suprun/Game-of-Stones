from std.sys.defines import get_defined_string

from std.memory import Pointer
from std.time import perf_counter_ns
from std.math import sqrt
from std.logger import Logger

from score import Score, Draw, is_win, is_loss, is_draw, is_decisive
from traits import TTree, TGame

comptime logging_level = get_defined_string["LOGGING_LEVEL", "NOTSET"]()
comptime assert_mode = get_defined_string["ASSERT", "none"]()


struct Mcts[G: TGame, c: Float64](TTree):
    comptime Game = Self.G
    comptime MctsNode = Node[Self.G, Self.c]

    var root: Self.MctsNode
    var logger: Logger[]

    def __init__(out self):
        self.root = {{}}
        self.logger = Logger(prefix="mcts: ")

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        var moves = game.moves()
        assert len(moves) > 0

        if len(moves) == 1:
            return [moves[0]]
        var all_draws = True
        for move in moves:
            if is_win(move.score()):
                return self._pv()
            if not is_decisive(move.score()):
                all_draws = False

        if all_draws:
            return self._pv()

        self.root = {{}}
        var deadline = perf_counter_ns() + max_time_ms * 1_000_000
        while perf_counter_ns() < deadline:
            if self.expand(game):
                break
            assert len(self.root.children) > 0
            var n_children = 0
            for ref child in self.root.children:
                if not is_decisive(child.move.score()):
                    n_children += 1
            if n_children == 1:
                break

        return self._pv()

    def expand(mut self, game: Self.G, out done: Bool):
        if is_decisive(self.root.move.score()):
            return True

        var g = game.copy()
        self.root._expand(g)

        if is_decisive(self.root.move.score()):
            return True

        var undecided = 0
        for ref child in self.root.children:
            if not is_decisive(child.move.score()):
                undecided += 1
        return undecided < 2

    def _pv(self) -> List[Self.G.Move]:
        var pv = List[Self.G.Move]()
        self.root._pv(pv)
        return pv^

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

        self.n_sims += 1
        var best_score = Score.MIN
        var all_draws = True
        var has_draw = False
        for ref child in self.children:
            var score = child.move.score()
            best_score = max(best_score, score)
            if is_draw(score):
                has_draw = True
            elif not is_decisive(score):
                all_draws = False

        # '+ 0.0' is to avoid acidental 'Draw's
        self.move.set_score(Draw if all_draws and has_draw else -best_score + 0.0)

    def select_node(self) -> Int:
        assert len(self.children) > 0
        var selected_child_idx = -1
        var max_v = Float64.MIN
        for child_idx in range(len(self.children)):
            ref child = self.children[child_idx]
            if is_decisive(child.move.score()):
                continue
            var v = Float64(child.move.score()) + Self.c * sqrt(Float64(self.n_sims)) / Float64(child.n_sims)
            if max_v < v:
                max_v = v
                selected_child_idx = child_idx
        assert selected_child_idx >= 0
        return selected_child_idx

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
            if is_loss(child.move.score()):
                continue
            elif is_win(child.move.score()):
                return child
            elif is_draw(child.move.score()):
                has_draw = True
                draw_node_idx = idx
                continue

            ref best_child = self.children[best_child_idx]
            if (
                best_child.n_sims < child.n_sims
                or best_child.n_sims == child.n_sims
                and best_child.move.score() < child.move.score()
            ):
                best_child_idx = idx

        if has_draw and self.children[best_child_idx].move.score() < 0:
            return self.children[draw_node_idx]

        return self.children[best_child_idx]

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.move)

    def write_repr_to[W: Writer](self, mut writer: W):
        self.write_repr_to(writer, 0)

    def write_repr_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write(depth, ": ", "|   " * depth, repr(self.move), " sims: ", self.n_sims, "\n")
        if depth >= 2:
            return
        if self.children:  # unnecessary check to silence LSP warning
            for child in self.children:
                child.write_repr_to(writer, depth + 1)
