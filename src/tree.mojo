from math import sqrt
from memory import Pointer
from utils.numerics import neg_inf

from game import TGame, TScore

struct Tree[Game: TGame, c: Float64](Stringable, Writable):
    var root: Node[Game, c]

    fn __init__(out self):
        self.root = Node[Game, c]((Game.Move(), Game.Score(0)))
        
    fn expand(mut self, game: Game, out done: Bool):
        if self.root.score.isdecisive():
            return True
        else:
            var g = game
            self.root._expand(g)
        
        if self.root.score.isdecisive():
            return True

        var undecided = 0
        for _ in self.root.children:
            if not self.root.score.isdecisive():
                undecided += 1
        return undecided == 1

    fn best_move(self) -> Game.Move:
        return self.root.best_move()
        
    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.root.write_to(writer)

    fn debug_best_moves(self):
        for ref node in self.root.children:
            print("  ", node.move, String(node.score), node.n_sims)

struct Node[Game: TGame, c: Float64](Copyable, Movable, Representable, Stringable, Writable):
    var move: Game.Move
    var score: Game.Score
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: (Game.Move, Game.Score)):
        self.move = move[0]
        self.score = move[1]
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, mut game: Game):
        if not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0, "Function moves(...) returns empty result.")

            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Node[Game, c](move))
                if move[1].isdecisive():
                    continue
        else:
            var parent_sims = sqrt(Float64(self.n_sims))
            var selected_child_idx = 0
            var maxV = neg_inf[DType.float64]()
            for child_idx in range(len(self.children)):
                ref child = self.children[child_idx]
                if child.score.isdecisive():
                    continue
                var v = Float64(child.score) + self.c * parent_sims / Float64(child.n_sims)
                if maxV < v:
                    maxV = v
                    selected_child_idx = child_idx
            ref selected_child = self.children[selected_child_idx]
            game.play_move(selected_child.move)
            selected_child._expand(game)

        self.n_sims = 0
        var max_score = neg_inf[DType.float64]()
        var all_draws = True
        var all_losses = True
        var has_draw = False
        for child in self.children:
            self.n_sims += child.n_sims
            if child.score.isloss():
                continue
            all_losses = False
            if child.score.iswin():
                self.score = Game.Score.loss()
                return
            elif child.score.isdraw():
                has_draw = True
                max_score = max(max_score, 0)
                continue
            all_draws = False
            max_score = max(max_score, Float64(child.score))
        if all_losses:
            self.score = Game.Score.win()
        elif has_draw and all_draws:
            self.score = Game.Score.draw()
        else:
            self.score = Game.Score(-max_score)

    fn best_move(self, out result: Game.Move):
        debug_assert(len(self.children) > 0, "Function node.best_move() is called with no children.")
        var has_draw = False
        var draw_move = self.children[-1].move
        var best_child = Pointer(to = self.children[-1])
        for ref child in self.children:
            if child.score.isloss():
                continue
            if child.score.iswin():
                return child.move
            if child.score.isdraw():
                has_draw = True
                draw_move = child.move
            if best_child[].n_sims < child.n_sims:
                best_child = Pointer(to = child)
        if has_draw and Float64(best_child[].score) < 0:
            return draw_move
        result = best_child[].move

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self.move, " v: ", String(self.score), " s: ", self.n_sims, "\n")
        if self.children:
            for child in self.children:
                child.write_to(writer, depth + 1)
