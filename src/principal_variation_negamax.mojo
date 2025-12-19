from time import perf_counter_ns
from sys import env_get_int
from logger import Logger

from score import Score
from traits import TTree, TGame, MoveScore


comptime Idx = UInt32
comptime nil: Idx = 0


@register_passable("trivial")
@fieldwise_init
struct Node[G: TGame](Copyable):
    var move: Self.G.Move
    var score: Score
    var first_child: Idx
    var last_child: Idx

    @staticmethod
    @parameter
    fn greater(a: Self, b: Self) -> Bool:
        return a.score > b.score


struct PrincipalVariationNegamax[G: TGame](TTree, Writable):
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
        var max_depth = 0
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        var start = perf_counter_ns()
        while True:
            var score = self._search(0, game, Score.loss(), Score.win(), 0, max_depth, deadline)
            var best_move = self.best_move()
            if not score.is_set():
                return best_move
            self.logger.debug("=== max depth: ", max_depth, " move:", best_move, " time:", (perf_counter_ns() - start) / 1_000_000_000)
            # print(self)
            if best_move.score.is_decisive():
                return best_move
            max_depth += 1

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

        if self.nodes[parent_idx].first_child == nil:
            var moves = game.moves()
            debug_assert(len(moves) > 0)
            
            if self.nodes.capacity < len(self.nodes) + len(moves):
                self.nodes.reserve(self.nodes.capacity * 2 + len(moves))
                print("### reserved", self.nodes.capacity * 2 + len(moves))

            var child_idx = len(self.nodes)
            self.nodes.resize(unsafe_uninit_length = len(self.nodes) + len(moves))
            self.nodes[parent_idx].first_child = child_idx
            self.nodes[parent_idx].last_child = child_idx + len(moves)
            for move in moves:
                ref child_node = self.nodes[child_idx]
                child_node.move = move.move
                child_node.score = move.score
                child_node.first_child = nil
                child_idx += 1

        ref parent = self.nodes[parent_idx]
        var best_score = Score.loss()

        if depth == max_depth:
            for child_idx in range(parent.first_child, parent.last_child):
                best_score = max(best_score, self.nodes[child_idx].score)
            self.nodes[parent_idx].score = -best_score
            return best_score

        sort[Node[Self.G].greater](self.nodes[Int(parent.first_child) : Int(parent.last_child)])

        if self.nodes[parent_idx].score.is_win():
            self.nodes[parent_idx].score = Score.loss()
            return Score.win()

        for child_idx in range(parent.first_child + 1, parent.last_child):
            ref child = self.nodes[child_idx]
            if not child.score.is_decisive():
                child.score = Score()

        var child_idx = parent.first_child

         # Full window search
        while child_idx < parent.last_child:
            ref child1 = self.nodes[child_idx]

            if child1.score.is_decisive():
                if best_score < child1.score:
                    best_score = child1.score
                    alpha = max(alpha, child1.score)
                if child1.score > beta or child1.score.is_win():
                    self.nodes[parent_idx].score = -best_score
                    return best_score

                child_idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child1.move)

            # print(">>>2 node: [", child_idx, "]  depth: ", depth + 1, "/", max_depth, "  [", -beta, ":", -alpha, "]", sep="")
            self.nodes[child_idx].score = -self._search(child_idx, g, -beta, -alpha, depth + 1, max_depth, deadline)
            ref child2 = self.nodes[child_idx]
            # print("<<<2 node: [", child_idx, "]  depth: ", depth + 1, "/", max_depth, "  [", -beta, ":", -alpha, "]  score: ", child2.score, sep="")
            if not child2.score.is_set():
                return Score()

            if best_score < child2.score:
                best_score = child2.score
                alpha = max(alpha, best_score)

            if child2.score > beta or child2.score.is_win():
                self.nodes[parent_idx].score = -best_score
                return best_score

            child_idx += 1

            if alpha != Score.loss() and child2.score >= alpha:
                break

        # Scout search
        while child_idx < parent.last_child:
            ref child1 = self.nodes[child_idx]

            if child1.score.is_decisive():
                if best_score < child1.score:
                    best_score = child1.score
                    alpha = max(alpha, best_score)
                if child1.score > beta or child1.score.is_win():
                    self.nodes[parent_idx].score = -best_score
                    return best_score

                child_idx += 1
                continue

            var g = game.copy()
            _ = g.play_move(child1.move)

            # print(">>>3 node: [", child_idx, "]  depth: ", depth + 1, "/", max_depth, "  [", -alpha, ":", -alpha, "]", sep="")
            self.nodes[child_idx].score = -self._search(child_idx, g, -alpha, -alpha, depth + 1, max_depth, deadline)
            ref child2 = self.nodes[child_idx]
            # print("<<<3 node: [", child_idx, "]  depth: ", depth + 1, "/", max_depth, "  [", -alpha, ":", -alpha, "]  score: ", child2.score, sep="")

            if best_score < child2.score:
                best_score = child2.score

            if child2.score > beta or child2.score.is_win():
                self.nodes[parent_idx].score = -best_score
                return best_score

            if best_score > alpha and depth < max_depth - 1:
                alpha = best_score
                # print(">>>4 node: [", child_idx, "]  depth: ", depth + 1, "/", max_depth, "  [", -beta, ":", -alpha, "]", sep="")
                self.nodes[child_idx].score = -self._search(child_idx, g, -beta, -alpha, depth + 1, max_depth, deadline)
                ref child3 = self.nodes[child_idx]
                # print("<<<4 node: [", child_idx, "]  depth: ", depth + 1, "/", max_depth, "  [", -beta, ":", -alpha, "]  score: ", child3.score, sep="")

                if best_score < child3.score:
                    best_score = child3.score
                    alpha = max(alpha, best_score)

                if child3.score > beta or child3.score.is_win():
                    self.nodes[parent_idx].score = -best_score
                    return best_score

            child_idx += 1

        self.nodes[parent_idx].score = -best_score
        return best_score

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, depth=0, node_idx=0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int, node_idx: Idx):
        ref parent = self.nodes[node_idx]
        writer.write("|   " * depth, "[", node_idx, "] ", parent.move, " ", parent.score, "\n")
        if parent.first_child < parent.last_child: # TODO Silence Mojo warning
            for child_idx in range(parent.first_child, parent.last_child):
                    self.write_to(writer, depth + 1, child_idx)
