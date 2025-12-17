from time import perf_counter_ns
from sys import env_get_int
from logger import Logger

from score import Score
from traits import TTree, TGame, MoveScore


comptime Idx = UInt32
comptime nil: Idx = 0


@register_passable("trivial")
struct Node[G: TGame](Copyable, Comparable):
    var move: Self.G.Move
    var score: Score
    var first_child: Idx
    var last_child: Idx

    fn __init__(out self):
        self.move = Self.G.Move()
        self.score = Score()
        self.first_child = 0
        self.last_child = 0

    fn __lt__(self, rhs: Self) -> Bool:
        return self.score < rhs.score

    fn __eq__(self, rhs: Self) -> Bool:
        return self.score == rhs.score

    @staticmethod
    @parameter
    fn greater(a: Self, b: Self) -> Bool:
        return a.score > b.score


struct PrincipalVariationNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var nodes: List[Node[Self.G]]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Principal Variation Negamax With Memory"

    fn __init__(out self):
        self.nodes = List[Node[Self.G]]()
        self.nodes.resize(unsafe_uninit_length=1)
        ref root = self.nodes[0]
        root.move = Self.G.Move()
        root.score = Score()
        root.first_child = nil
        self.logger = Logger(prefix="pvs: ")

    fn reset(mut self):
        self.nodes.shrink(1)
        self.nodes[0].first_child = nil


    fn search(mut self, game: Self.G, duration_ms: UInt) -> MoveScore[Self.G.Move]:
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        var start = perf_counter_ns()
        while True:
            var score = self._search(0, game, Score.loss(), Score.win(), 0, depth, deadline)
            var best_move = self.best_move()
            if not score.is_set():
                return best_move
            self.logger.debug("=== max depth: ", depth, " move:", best_move, " time:", (perf_counter_ns() - start) / 1_000_000_000)
            if best_move.score.is_decisive():
                return best_move
            depth += 1
            return best_move

    fn best_move(self) -> MoveScore[Self.G.Move]:
        var best_node_idx = self.nodes[0].first_child
        var best_score = self.nodes[best_node_idx].score
        for child_idx in range(best_node_idx + 1, self.nodes[0].last_child):
            if best_score < self.nodes[child_idx].score:
                best_node_idx = child_idx
                best_score = self.nodes[child_idx].score

        return MoveScore(self.nodes[best_node_idx].move, self.nodes[best_node_idx].score)

    fn _search(mut self, parent_idx: Idx, game: Self.G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        if perf_counter_ns() > deadline:
            return Score()

        ref parent = self.nodes[parent_idx]
        if parent.first_child == nil:
            var moves = game.moves()
            debug_assert(len(moves) > 0)
            if self.nodes.capacity < len(self.nodes) + len(moves):
                self.nodes.reserve(self.nodes.capacity * 2 + len(moves))
                self.nodes.resize(unsafe_uninit_length = len(self.nodes) + len(moves))
                var child_idx = len(self.nodes)
                parent.first_child = child_idx
                parent.last_child = child_idx + len(moves)
                for move in moves:
                    ref child_node = self.nodes[child_idx]
                    child_node.move = move.move
                    child_node.score = move.score
                    child_node.first_child = nil
                    child_idx += 1

        var best_score = Score.loss()

        if depth == max_depth:
            for child_idx in range(parent.first_child, parent.last_child):
                best_score = max(best_score, self.nodes[child_idx].score)
            return best_score

        var span = Span(self.nodes)
        sort(span)
        # sort(self.nodes)
        # sort[Node.greater](self.nodes)
        # sort[Self.greater](self.nodes[Int(parent.first_child) : Int(parent.last_child)])

        if self.nodes[parent_idx].score.is_win():
            return Score.win()

        for child_idx in range(parent.first_child + 1, parent.last_child):
            ref child = self.nodes[child_idx]
            if not child.score.is_decisive():
                child.score = Score()

        var child_idx: Idx = 0

         # Full window search
        while child_idx < parent.last_child:
            ref child = self.nodes[child_idx]

            if child.score.is_decisive():
                if best_score < child.score:
                    best_score = child.score
                    alpha = max(alpha, child.score)
                if child.score > beta or child.score.is_win():
                    return best_score

                child_idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child.move)

            child.score = -self._search(child_idx, g, -beta, -alpha, depth + 1, max_depth, deadline)
            if not child.score.is_set():
                return Score()

            if best_score < child.score:
                best_score = child.score
                alpha = max(alpha, best_score)

            if child.score > beta or child.score.is_win():
                return best_score

            child_idx += 1

            if alpha != Score.loss() and child.score >= alpha:
                break

        # Scout search
        while child_idx < parent.last_child:
            ref child = self.nodes[child_idx]

            if child.score.is_decisive():
                if best_score < child.score:
                    best_score = child.score
                    alpha = max(alpha, best_score)
                if child.score > beta or child.score.is_win():
                    return best_score

                child_idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child.move)

            child.score = -self._search(child_idx, g, -alpha, -alpha, depth + 1, max_depth, deadline)

            if best_score < child.score:
                best_score = child.score

            if child.score > beta or child.score.is_win():
                return best_score

            if best_score > alpha and depth < max_depth - 1:
                alpha = best_score
                child.score = -self._search(child_idx, g, -beta, -alpha, depth + 1, max_depth, deadline)

                if best_score < child.score:
                    best_score = child.score
                    alpha = max(alpha, best_score)

                if child.score > beta or child.score.is_win():
                    return best_score

            child_idx += 1

        return best_score

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, depth=0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self.move, " ", self.score, "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_to(writer, depth + 1)
