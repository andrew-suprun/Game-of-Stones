from math import log2, sqrt
from memory import Pointer

from game import Game, Move, Score, is_decisive, is_win, is_draw, is_loss, win, draw, loss

struct Tree[Game: Game, c: Score](Stringable, Writable):
    var root: Node[Game, c]
    var top_moves: List[(Move, Score)]

    fn __init__(out self):
        self.root = Node[Game, c](Move(0, 0, 0, 0), 0)
        self.top_moves = List[(Move, Score)]()

    fn expand(mut self, mut game: Game, out done: Bool):
        if is_decisive(self.root.value):
            return True
        else:
            self.root._expand(game, self.top_moves)
        
        if is_decisive(self.root.value):
            return True

        var undecided = 0
        for child in self.root.children:
            if not is_decisive(child.value):
                undecided += 1
        return undecided == 1

    fn value(self, out result: Score):
        result = -self.root.value
        
    fn best_move(self, out result: Move):
        result = self.root._best_move()
        
    fn reset(mut self):
        self.root = Node[Game, c](Move(0, 0, 0, 0), 0)

    fn __str__(self, out result: String):
        result = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.root.write_to(writer, 0)

    fn debug_print_root_children(self):
        self.root.debug_print_root_children()

@value
struct Node[Game: Game, c: Score](Copyable, Movable, Stringable, Writable):
    var move: Move
    var value: Score
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: Move, value: Score):
        self.move = move
        self.value = value
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, mut g: Game, mut top_moves: List[(Move, Score)]):
        if not self.children:
            g.top_moves(top_moves)
            debug_assert(len(top_moves) > 0, "Function top_moves(...) returns empty result.")

            self.children.reserve(len(top_moves))
            for move in top_moves:
                self.children.append(Node[Game, c](move[0], move[1]))
        else:
            ref selected_child = self.children[0]
            var n_sims = self.n_sims
            var log_parent_sims = log2(Score(n_sims))
            var maxV = loss
            for ref child in self.children:
                if is_decisive(child.value):
                    continue
                var v = child.value + self.c * sqrt(log_parent_sims / Score(child.n_sims))
                if v > maxV:
                    maxV = v
                    selected_child = child
            var move = selected_child.move
            g.play_move(move)
            selected_child._expand(g, top_moves)
            g.undo_move()

        self.n_sims = 0
        self.value = win
        var has_draw = False
        var all_draws = True
        for child in self.children:
            if is_win(child.value):
                self.value = -child.value
                return
            elif is_draw(child.value):
                has_draw = True
                continue
            all_draws = False
            if is_loss(child.value):
                continue
            self.n_sims += child.n_sims
            if self.value >= -child.value:
                self.value = -child.value
        if all_draws:
            self.value = draw
        elif has_draw and self.value > 0:
            self.value = 0

    fn _best_move(self, out result: Move):
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
        writer.write(self.move, " v: ", self.value, " s: ", self.n_sims)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self, "\n")
        if self.children:
            for ref child in self.children:
                child.write_to(writer, depth + 1)

    fn debug_print_root_children(self):
        print(self)
        for child in self.children:
            print("  ", child)
