from math import log2, sqrt
from memory import Pointer

import score
from game import TGame

struct Tree[Game: TGame, c: score.Score](Stringable, Writable):
    var root: Node[Game, c]

    fn __init__(out self):
        self.root = Node[Game, c]((Game.Move(), score.Score(0)))
        
    fn expand(mut self, game: Game, out done: Bool):
        if score.isdecisive(self.root.score):
            return True
        else:
            var g = game
            self.root._expand(g)
        
        if score.isdecisive(self.root.score):
            return True

        var undecided = 0
        for _ in self.root.children:
            if not score.isdecisive(self.root.score):
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
            print("  ", node.move, score.str(node.score), node.n_sims)

struct Node[Game: TGame, c: score.Score](Copyable, Movable, Representable, Stringable, Writable):
    var move: Game.Move
    var score: score.Score
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: (Game.Move, score.Score)):
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
                if score.isdecisive(move[1]):
                    continue
        else:
            var log_parent_sims = score.Score(self.n_sims)
            var selected_child_idx = 0
            var maxV = score.loss
            for child_idx in range(len(self.children)):
                ref child = self.children[child_idx]
                if score.isdecisive(child.score):
                    continue
                var v = child.score + self.c * log_parent_sims / score.Score(child.n_sims)
                if maxV < v:
                    maxV = v
                    selected_child_idx = child_idx
            ref selected_child = self.children[selected_child_idx]
            game.play_move(selected_child.move)
            selected_child._expand(game)

        self.n_sims = 0
        var max_score = self.children[0].score
        var all_draws = True
        var all_losses = True
        var has_draw = False
        for child in self.children:
            self.n_sims += child.n_sims
            if score.isloss(child.score):
                continue
            all_losses = False
            if score.iswin(child.score):
                self.score = score.loss
                return
            elif score.isdraw(child.score):
                has_draw = True
                max_score = max(max_score, 0)
                continue
            all_draws = False
            max_score = max(max_score, child.score)
        if all_losses:
            self.score = score.win
        elif has_draw and all_draws:
            print("draw", self.move)
            self.score = score.draw
        else:
            self.score = score.invert(max_score)

    fn best_move(self, out result: Game.Move):
        debug_assert(len(self.children) > 0, "Function node.best_move() is called with no children.")
        var has_draw = False
        var draw_move = self.children[-1].move
        var best_child = Pointer(to = self.children[-1])
        for ref child in self.children:
            if score.isloss(child.score):
                continue
            if score.iswin(child.score):
                return child.move
            if score.isdraw(child.score):
                has_draw = True
                draw_move = child.move
            if best_child[].n_sims < child.n_sims:
                best_child = Pointer(to = child)
        if has_draw and best_child[].score < 0:
            return draw_move
        result = best_child[].move

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        if score.isdecisive(self.score):
            writer.write("|   " * depth, self.move, " d: ", score.str(self.score), "\n")
        else:
            writer.write("|   " * depth, self.move, " v: ", self.score, " s: ", self.n_sims, "\n")
        if self.children:
            for child in self.children:
                child.write_to(writer, depth + 1)
