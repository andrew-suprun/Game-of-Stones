from memory import Pointer
from utils.numerics import inf, neg_inf, isinf
from time import perf_counter_ns

from tree import TTree
from game import TGame, Score, MoveScore, Decision, draw

struct Mcts[G: TGame, max_moves: Int, c: Float64, no_legal_moves_decision: Decision](TTree, Stringable, Writable):
    alias Game = G
    alias MctsNode = Node[G, max_moves, c, no_legal_moves_decision]

    var root: Self.MctsNode

    fn __init__(out self):
        self.root = Self.MctsNode(G.Move(), Score(0), False)
        
    fn search(mut self, game: G, max_time_ms: Int) -> (Score, List[G.Move]):
        self.root = Self.MctsNode(G.Move(), Score(0), False)
        var deadline = perf_counter_ns() + max_time_ms * 1_000_000
        while perf_counter_ns() < deadline:
            if self.expand(game):
                break

        var child_node = self._best_child()
        return (child_node.score, [child_node.move])

    fn expand(mut self, game: G, out done: Bool):
        if self.root.decisive:
            return True

        self.root._expand(game)

        if self.root.decisive:
            return True

        var undecided = 0
        for ref child in self.root.children:
            if not child.decisive:
                undecided += 1
        return undecided < 2

    fn best_move(self) -> G.Move:
        return self._best_child().move

    fn _best_child(self) -> Self.MctsNode:
        debug_assert(len(self.root.children) > 0, "Function node.best_child() is called with no children.")
        var has_draw = False
        var draw_node = self.root.children[-1]
        var best_child = Pointer(to = self.root.children[-1])
        for ref child in self.root.children:
            if child.decisive:
                if child.score < 0:
                    continue
                if child.score > 0:
                    return child
                else:
                    has_draw = True
                    draw_node = child
            
            if best_child[].n_sims < child.n_sims:
                best_child = Pointer(to = child)
        if has_draw and Float64(best_child[].score) < 0:
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
            result.write("  ", node.move, " ", node.score, " ", node.decisive, " ", node.n_sims, "\n")
        return result

struct Node[G: TGame, max_moves: Int, c: Float64, no_legal_moves_decision: Decision](Copyable, Movable, Representable, Stringable, Writable):
    var move: G.Move
    var score: Score
    var decisive: Bool
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: G.Move, score: Score, decisive: Bool):
        self.move = move
        self.score = score
        self.decisive = decisive
        self.children = List[Self]()
        self.n_sims = 1
        debug_assert(self.decisive or not isinf(self.score))

    fn _expand(mut self, game: G):
        if not self.children:
            var moves = game.moves(max_moves)
            if not moves:
                self.decisive = True
                if no_legal_moves_decision == draw:
                    self.score = Score(0)
                else:
                    self.score = Score(neg_inf[DType.float32]())

            else:
                self.children.reserve(len(moves))
                for move in moves:
                    debug_assert(move.terminal or not isinf(self.score))
                    self.children.append(Self(move.move, move.score, move.terminal))
        else:
            var exp_factor = self.c * Float64(self.n_sims)
            ref selected_child = self.children[Self.select_node(self.children, exp_factor)]
            var g = game
            g.play_move(selected_child.move)
            selected_child._expand(g)

        self.n_sims = 0
        var max_score = neg_inf[DType.float64]()
        var all_draws = True
        var all_losses = True
        var has_draw = False
        for child in self.children:
            self.n_sims += child.n_sims
            if child.decisive and child.score < 0:
                continue
            all_losses = False
            if child.decisive and child.score > 0:
                self.score = neg_inf[DType.float32]()
                self.decisive = True
                return
            elif child.decisive and child.score == 0:
                has_draw = True
                max_score = max(max_score, 0)
                continue
            all_draws = False
            max_score = max(max_score, Float64(child.score))
        if all_losses:
            self.score = inf[DType.float32]()
            self.decisive = True
        elif has_draw and all_draws:
            self.score = 0
            self.decisive = True
        else:
            self.score = Score(-max_score)
        debug_assert(self.decisive or not isinf(self.score))

    @staticmethod
    fn select_node(nodes: List[Self], exp_factor: Float64) -> Int:
        var selected_child_idx = -1
        var maxV = neg_inf[DType.float64]()
        for child_idx in range(len(nodes)):
            ref child = nodes[child_idx]
            if child.decisive:
                continue
            var v = Float64(child.score) + exp_factor / Float64(child.n_sims)
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
        writer.write("|   " * depth, self.move)
        if self.decisive:
            if self.score > 0:
                writer.write(" win")
            elif self.score < 0:
                writer.write(" loss")
            else:
                writer.write(" draw")
        else:
            writer.write(" ", String(self.score))
        writer.write(" sims: ", self.n_sims, "\n")


        if self.children:
            for child in self.children:
                child.write_to(writer, depth + 1)
