from memory import Pointer
from time import perf_counter_ns

from score import Score, win, loss, draw, is_win, is_loss, is_draw, is_decisive, str_score
from tree import TTree
from game import TGame, MoveScore

struct Mcts[G: TGame, max_moves: Int, c: Score, no_legal_moves_decision: Score](TTree, Stringable, Writable):
    alias Game = G
    alias MctsNode = Node[G, max_moves, c, no_legal_moves_decision]

    var root: Self.MctsNode

    fn __init__(out self):
        self.root = Self.MctsNode(G.Move(), Score(0))
        
    fn search(mut self, game: G, max_time_ms: Int) -> (Score, List[G.Move]):
        self.root = Self.MctsNode(G.Move(), Score(0))
        var deadline = perf_counter_ns() + max_time_ms * 1_000_000
        while perf_counter_ns() < deadline:
            if self.expand(game):
                break

        var child_node = self._best_child()
        return (child_node.score, [child_node.move])

    fn expand(mut self, game: G, out done: Bool):
        if is_decisive(self.root.score):
            return True

        self.root._expand(game)

        if is_decisive(self.root.score):
            return True

        var undecided = 0
        for ref child in self.root.children:
            if not is_decisive(child.score):
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
            if is_loss(child.score):
                continue
            elif is_win(child.score):
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
            result.write("  ", node.move, " ", str_score(node.score), " ", node.n_sims, "\n")
        return result

struct Node[G: TGame, max_moves: Int, c: Score, no_legal_moves_decision: Score](Copyable, Movable, Representable, Stringable, Writable):
    var move: G.Move
    var score: Score
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: G.Move, score: Score):
        self.move = move
        self.score = score
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, game: G):
        if not self.children:
            var moves = game.moves(max_moves)
            if not moves:
                self.score = no_legal_moves_decision
            else:
                self.children.reserve(len(moves))
                for move in moves:
                    self.children.append(Self(move.move, move.score))
        else:
            var exp_factor = self.c * Score(self.n_sims)
            ref selected_child = self.children[Self.select_node(self.children, exp_factor)]
            var g = game
            g.play_move(selected_child.move)
            selected_child._expand(g)

        self.n_sims = 0
        var max_score = loss
        var all_draws = True
        var all_losses = True
        var has_draw = False
        for ref child in self.children:
            self.n_sims += child.n_sims
            if is_loss(child.score):
                continue
            all_losses = False
            if is_win(child.score):
                self.score = loss
                return
            elif is_draw(child.score):
                has_draw = True
                max_score = max(max_score, 0)
                continue
            all_draws = False
            max_score = max(max_score, child.score)
        if all_losses:
            self.score = win
        elif has_draw and all_draws:
            self.score = draw
        else:
            self.score = -max_score

    @staticmethod
    fn select_node(nodes: List[Self], exp_factor: Score) -> Int:
        var selected_child_idx = -1
        var maxV = loss
        for child_idx in range(len(nodes)):
            ref child = nodes[child_idx]
            if is_decisive(child.score):
                continue
            var v = child.score + exp_factor / Score(child.n_sims)
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
        writer.write("|   " * depth, self.move, " ", str_score(self.score), " sims: ", self.n_sims, "\n")
        if self.children:
            for child in self.children:
                child.write_to(writer, depth + 1)
