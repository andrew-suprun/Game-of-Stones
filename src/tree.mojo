from utils.numerics import inf, neg_inf
from math import log2, sqrt
from memory import Pointer

from game import TGame

struct Tree[Game: TGame, c: Float32](Stringable, Writable):
    var root: Node[Game, c]
    var top_moves: List[Game.Move]

    fn __init__(out self):
        self.root = Node[Game, c](Game.Move())
        self.top_moves = List[Game.Move]()

    fn expand(mut self, mut game: Game, out done: Bool):
        if self.root.move.is_decisive():
            return True
        else:
            self.root._expand(game, self.top_moves)
        
        if self.root.move.is_decisive():
            return True

        var undecided = 0
        for child in self.root.children:
            if not child.move.is_decisive():
                undecided += 1
        return undecided == 1

    fn value(self, out result: Float32):
        result = -self.root.value
        
    fn best_move(self, out result: Game.Move):
        result = self.root._best_move()
        
    fn reset(mut self):
        self.root = Node[Game, c](Game.Move(), 0)

    fn __str__(self, out result: String):
        result = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.root.write_to(writer, 0)

    fn debug_print_root_children(self):
        self.root.debug_print_root_children()

@fieldwise_init
struct Node[Game: TGame, c: Float32](Copyable, Movable, Stringable, Writable):
    var move: Game.Move
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: Game.Move):
        self.move = move
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, mut g: Game, mut top_moves: List[Game.Move]):
        if not self.children:
            g.top_moves(top_moves)
            debug_assert(len(top_moves) > 0, "Function top_moves(...) returns empty result.")

            self.children.reserve(len(top_moves))
            for move in top_moves:
                self.children.append(Node[Game, c](move))
        else:
            ref selected_child = self.children[0]
            var n_sims = self.n_sims
            var log_parent_sims = log2(Float32(n_sims))
            var maxV = neg_inf[DType.float32]()
            for ref child in self.children:
                if child.move.is_decisive():
                    continue
                var v = child.move.get_score() + self.c * sqrt(log_parent_sims / Float32(child.n_sims))
                if v > maxV:
                    maxV = v
                    selected_child = child
            var move = selected_child.move
            g.play_move(move)
            selected_child._expand(g, top_moves)
            g.undo_move()

        self.n_sims = 0
        self.move.set_score(1)
        self.move.set_decisive()
        var score = inf[DType.float32]()
        var has_draw = False
        var all_draws = True
        for child in self.children:
            if child.move.is_decisive() and child.move.get_score() > 0:
                self.move.set_decisive()
                self.move.set_score(-1)
                return
            elif child.move.is_decisive() and child.move.get_score() == 0:
                has_draw = True
                continue
            all_draws = False
            if child.move.is_decisive() and child.move.get_score() < 0:
                continue
            self.n_sims += child.n_sims
            var child_score = child.move.get_score()
            if score >= -child_score:
                score = -child_score
        if all_draws:
            self.move.set_score(0)
            self.move.set_decisive()
        elif has_draw and self.move.get_score() > 0:
            self.move.set_score(0)
        else:
            self.move.set_score(score)

    fn _best_move(self, out result: Game.Move):
        debug_assert(len(self.children) > 0, "Function node.best_move() is called with no children.")
        var best_child = Pointer(to = self.children[0])
        for ref child in self.children:
            if best_child[].value < child.value:
                best_child = Pointer(to = child)
            elif is_loss(best_child[].value) and best_child[].n_sims < child.n_sims:
                best_child = Pointer(to = child)
        result = best_child[].move

    fn __str__(self, out result: String):
        result = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.move, " v: ", self.move.get_score(), " s: ", self.n_sims)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self, "\n")
        if self.children:
            for ref child in self.children:
                child.write_to(writer, depth + 1)

    fn debug_print_root_children(self):
        print(self)
        for child in self.children:
            print("  ", child)
