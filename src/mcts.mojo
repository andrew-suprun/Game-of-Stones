from std.memory import Pointer
from std.time import perf_counter_ns
from std.math import sqrt
from std.logger import Logger

from fp_score import Score
from traits import TTree, TGame, MoveScore


struct Mcts[G: TGame, c: G.Score](TTree):
    comptime Game = Self.G
    comptime MctsNode = Node[Self.G, Self.c]

    var root: Self.MctsNode
    var logger: Logger[]

    def __init__(out self):
        self.root = {{{}, {}}}
        self.logger = Logger(prefix="mcts: ")

    def search(mut self, game: Self.G, max_time_ms: UInt) -> MoveScore[Self.G.Move, Self.G.Score]:
        var moves = game.moves()
        assert len(moves) > 0
        if len(moves) == 1:
            return moves[0]
        var all_draws = True
        for move in moves:
            if move.score.is_win():
                return move
            if not move.score.is_draw():
                all_draws = False
        if all_draws:
            return moves[0]
        self.root = {{{}, {}}}
        var best_node: Self.MctsNode = {{{}, {}}}
        var deadline = perf_counter_ns() + max_time_ms * 1_000_000
        while perf_counter_ns() < deadline:
            var done = self.expand(game)
            ref best_child = self._best_child()
            if best_node.move.move != best_child.move.move:
                best_node = best_child.copy()
                var sec = (deadline - perf_counter_ns()) / 1_000_000_000
                self.logger.debug("best move", best_node.move, "sims:", best_node.n_sims, " time ", sec)

            if done:
                break

        ref result = self._best_child()
        var sec = (deadline - perf_counter_ns()) / 1_000_000_000
        self.logger.debug("result   ", result.move, "sims:", result.n_sims, " time ", sec)

        return result.move

    def expand(mut self, game: Self.G, out done: Bool):
        if self.root.move.score.is_decisive():
            return True

        var g = game.copy()
        self.root._expand(g)

        if self.root.move.score.is_decisive():
            return True

        var undecided = 0
        for ref child in self.root.children:
            if not child.move.score.is_decisive():
                undecided += 1
        return undecided < 2

    def best_move(self) -> Self.G.Move:
        return self._best_child().move.move

    def _best_child(self) -> ref[self.root.children] Self.MctsNode:
        assert len(self.root.children) > 0
        var has_draw = False
        var last_idx = len(self.root.children)-1
        var draw_node = Pointer(to=self.root.children[last_idx])
        var best_child = Pointer(to=self.root.children[last_idx])
        for ref child in self.root.children:
            if child.move.score.is_loss():
                continue
            elif child.move.score.is_win():
                return child
            elif child.move.score.is_draw():
                has_draw = True
                draw_node = Pointer(to=child)
                continue

            if best_child[].n_sims < child.n_sims or best_child[].n_sims == child.n_sims and best_child[].move.score < child.move.score:
                best_child = Pointer(to=child)
        if has_draw and best_child[].move.score < 0:
            return draw_node[]
        return best_child[]

    def write_to[W: Writer](self, mut writer: W):
        for ref root in self.root.children:
            root.write_to(writer)

    def debug_roots(self) -> String:
        var result = "roots:\n"
        for ref node in self.root.children:
            result.write("  ", node.move, " sims ", node.n_sims, "\n")
        return result


struct Node[G: TGame, c: G.Score](Copyable, Writable):
    var move: MoveScore[Self.G.Move, Self.G.Score]
    var children: List[Self]
    var n_sims: Int32

    def __init__(out self, move: MoveScore[Self.G.Move, Self.G.Score]):
        self.move = move
        self.children = List[Self]()
        self.n_sims = 1

    def _expand(mut self, mut game: Self.G):
        if not self.children:
            var moves = game.moves()
            assert len(moves) > 0
            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Self(move))
        else:
            ref selected_child = self.children[Self.select_node(self.children)]
            _ = game.play_move(selected_child.move.move)
            selected_child._expand(game)

        self.n_sims = 1
        var max_score = Self.G.Score.loss()
        var all_draws = True
        var all_losses = True
        var has_draw = False
        for ref child in self.children:
            self.n_sims += child.n_sims
            if child.move.score.is_loss():
                continue
            all_losses = False
            if child.move.score.is_win():
                self.move.score = Self.G.Score.loss()
                return
            elif child.move.score.is_draw():
                has_draw = True
                max_score = max(max_score, 0)
                continue
            all_draws = False
            max_score = max(max_score, child.move.score)
        if all_losses:
            self.move.score = Self.G.Score.win()
        elif has_draw and all_draws:
            self.move.score = Self.G.Score.draw()
        else:
            self.move.score = -max_score

    @staticmethod
    def select_node(nodes: List[Self]) -> Int:
        var selected_child_idx = -1
        var maxV = Self.G.Score.loss()
        for child_idx in range(len(nodes)):
            ref child = nodes[child_idx]
            if child.move.score.is_decisive():
                continue
            var v = child.move.score - Self.c * Self.G.Score(sqrt(Float64(child.n_sims)))
            if maxV < v:
                maxV = v
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
