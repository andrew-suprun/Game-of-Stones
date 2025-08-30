from memory import Pointer
from time import perf_counter_ns
from math import log

from score import Score
from tree import TTree
from game import TGame, MoveScore


struct Mcts[G: TGame, c: Score](Stringable, TTree, Writable):
    alias Game = G
    alias MctsNode = Node[G, c]

    var root: Self.MctsNode

    fn __init__(out self):
        self.root = Self.MctsNode(MoveScore(G.Move(), Score(0)))

    fn search(mut self, game: G, max_time_ms: Int) -> MoveScore[G.Move]:
        var moves = game.moves()
        debug_assert(len(moves) > 0)
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
        self.root = Self.MctsNode(MoveScore(G.Move(), Score(0)))
        var deadline = perf_counter_ns() + max_time_ms * 1_000_000
        while perf_counter_ns() < deadline:
            if self.expand(game):
                break

        var child_node = self._best_child()
        return child_node.move

    fn expand(mut self, game: G, out done: Bool):
        if self.root.move.score.is_decisive():
            return True

        self.root._expand(game)

        if self.root.move.score.is_decisive():
            return True

        var undecided = 0
        for ref child in self.root.children:
            if not child.move.score.is_decisive():
                undecided += 1
        return undecided < 2

    fn best_move(self) -> G.Move:
        return self._best_child().move.move

    fn _best_child(self) -> Self.MctsNode:
        debug_assert(len(self.root.children) > 0)
        var has_draw = False
        var draw_node = self.root.children[-1]
        var best_child = Pointer(to=self.root.children[-1])
        for ref child in self.root.children:
            if child.move.score.is_loss():
                continue
            elif child.move.score.is_win():
                return child
            elif child.move.score.is_draw():
                has_draw = True
                draw_node = child
                continue

            if best_child[].n_sims < child.n_sims or 
                    best_child[].n_sims == child.n_sims and best_child[].move.score < child.move.score:
                best_child = Pointer(to=child)
        if has_draw and best_child[].move.score < 0:
            return draw_node
        return best_child[]

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        for ref root in self.root.children:
            root.write_to(writer)

    fn debug_roots(self) -> String:
        var result = "roots:\n"
        for ref node in self.root.children:
            result.write("  ", node.move, " sims ", node.n_sims, "\n")
        return result


struct Node[G: TGame, c: Score](Copyable, Movable, Representable, Stringable, Writable):
    var move: MoveScore[G.Move]
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: MoveScore[G.Move]):
        self.move = move
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, game: G):
        if not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0)
            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Self(move))
        else:
            ref selected_child = self.children[Self.select_node(self.children)]
            var g = game.copy()
            _ = g.play_move(selected_child.move.move)
            selected_child._expand(g)

        self.n_sims = 1
        var max_score = Score.loss()
        var all_draws = True
        var all_losses = True
        var has_draw = False
        for ref child in self.children:
            self.n_sims += child.n_sims
            if child.move.score.is_loss():
                continue
            all_losses = False
            if child.move.score.is_win():
                self.move.score = Score.loss()
                return
            elif child.move.score.is_draw():
                has_draw = True
                max_score = max(max_score, 0)
                continue
            all_draws = False
            max_score = max(max_score, child.move.score)
        if all_losses:
            self.move.score = Score.win()
        elif has_draw and all_draws:
            self.move.score = Score.draw()
        else:
            self.move.score = -max_score

    @staticmethod
    fn select_node(nodes: List[Self]) -> Int:
        var selected_child_idx = -1
        var maxV = Score.loss()
        for child_idx in range(len(nodes)):
            ref child = nodes[child_idx]
            if child.move.score.is_decisive():
                continue
            var v = child.move.score - Self.c * log(Score(child.n_sims).value)
            if maxV < v:
                maxV = v
                selected_child_idx = child_idx
        debug_assert(selected_child_idx >= 0)
        return selected_child_idx

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write(depth, ": ", "|   " * depth, self.move, " sims: ", self.n_sims, "\n")
        if self.children:
            for child in self.children:
                child.write_to(writer, depth + 1)
