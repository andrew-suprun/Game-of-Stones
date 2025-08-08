from memory import Pointer
from utils.numerics import inf, neg_inf
from time import perf_counter_ns

from tree import TTree
from game import TGame, Score, MoveScore

struct MCTS[G: TGame, max_moves: Int, c: Float64](TTree, Stringable, Writable):
    alias Game = G

    var roots: List[Node[G, max_moves, c]]
    var no_moves_score: Score

    fn __init__(out self, no_moves_score: Score):
        self.roots = List[Node[G, max_moves, c]]()
        self.no_moves_score = no_moves_score
        
    fn search(mut self, game: G, max_time_ms: Int) -> (Score, List[G.Move]):
        var deadline = perf_counter_ns() + max_time_ms * 1_000_000
        while perf_counter_ns() < deadline:
            if self.expand(game):
                break
        var child_node = self.best_child()
        return (child_node.score, [child_node.move])

    fn expand(mut self, game: G, out done: Bool):
        if not self.roots:
            var moves = game.moves(max_moves)
            self.roots.reserve(len(moves))
            for move in moves:
                self.roots.append(Node[G, max_moves, c](move))
            return False

        var n_sims = Int32(0)
        for ref root in self.roots:
            n_sims += root.n_sims

        var selected_idx = Node.select_node(self.roots, self.c * Float64(n_sims))
        ref root = self.roots[selected_idx]

        if root.decisive:
            return True
        else:
            var g = game
            g.play_move(root.move)
            root._expand(g)

        if root.decisive and root.score > 0:
            return True

        var undecided = 0
        for ref root in self.roots:
            if not root.decisive:
                undecided += 1
        return undecided < 2

    fn best_child(self) -> Node[G, max_moves, c]:
        debug_assert(len(self.roots) > 0, "Function node.best_child() is called with no children.")
        var has_draw = False
        var draw_node = self.roots[-1]
        var best_child = Pointer(to = self.roots[-1])
        for ref child in self.roots:
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
        for ref root in self.roots:
            root.write_to(writer)

    fn debug_roots(self) -> String:
        var result = "roots:\n"
        for ref node in self.roots:
            result.write("  ", node.move, " ", node.score, " ", node.decisive, " ", node.n_sims, "\n")
        return result

struct Node[G: TGame, max_moves: Int, c: Float64](Copyable, Movable, Representable, Stringable, Writable):
    var move: G.Move
    var score: Score
    var decisive: Bool
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: MoveScore[G.Move]):
        self.move = move.move
        self.score = move.score
        self.decisive = move.terminal
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, mut game: G):
        if not self.children:
            var moves = game.moves(max_moves)
            if not moves:
                self.score = Score(0)
                self.decisive = True
                return

            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Node[G, max_moves, c](move))
        else:
            var exp_factor = self.c * Float64(self.n_sims)
            ref selected_child = self.children[Self.select_node(self.children, exp_factor)]
            game.play_move(selected_child.move)
            selected_child._expand(game)

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

    @staticmethod
    fn select_node(nodes: List[Node[G, max_moves, c]], exp_factor: Float64) -> Int:
        var selected_child_idx = 0
        var maxV = neg_inf[DType.float64]()
        for child_idx in range(len(nodes)):
            ref child = nodes[child_idx]
            if child.decisive:
                continue
            var v = Float64(child.score) + exp_factor / Float64(child.n_sims)
            if maxV < v:
                maxV = v
                selected_child_idx = child_idx
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
