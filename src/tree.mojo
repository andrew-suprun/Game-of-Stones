from math import log2, sqrt
from memory import Pointer

from game import TGame, Decision

struct Tree[Game: TGame, c: Float32](Stringable, Writable):
    var root: Node[Game, c]

    fn __init__(out self):
        self.root = Node[Game, c]((Game.Move(), Float32(0), Decision.undecided))
        
    fn expand(mut self, game: Game, out done: Bool):
        if self.root.decision != Decision.undecided:
            return True
        else:
            var g = game
            self.root._expand(g)
        
        if self.root.decision != Decision.undecided:
            return True

        var undecided = 0
        for _ in self.root.children:
            if not self.root.decision != Decision.undecided:
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
            print("  ", node.move, node.score, node.n_sims, node.decision)

struct Node[Game: TGame, c: Float32](Copyable, Movable, Representable, Stringable, Writable):
    alias Score = Float32

    var move: Game.Move
    var score: Float32
    var decision: Decision
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: (Game.Move, Float32, Decision)):
        self.move = move[0]
        self.score = move[1]
        self.decision = move[2]
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, mut game: Game):
        if not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0, "Function moves(...) returns empty result.")

            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Node[Game, c](move))
                if move[2] != Decision.undecided:
                    continue
        else:
            var log_parent_sims = log2(Float64(self.n_sims))
            var selected_child_idx = 0
            var maxV = Float64(self.children[0].score)
            for child_idx in range(1, len(self.children)):
                ref child = self.children[child_idx]
                if child.decision != Decision.undecided:
                    continue
                var v = Float64(child.score) + Float64(self.c) * sqrt(log_parent_sims / Float64(child.n_sims))
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
            if child.decision == Decision.loss:
                continue
            all_losses = False
            if child.decision == Decision.win:
                self.decision = Decision.loss
                return
            elif child.decision == Decision.draw:
                has_draw = True
                max_score = max(max_score, 0)
                continue
            all_draws = False
            max_score = max(max_score, child.score)
        if all_losses:
            self.decision = Decision.win
        elif has_draw and all_draws:
            self.decision = Decision.draw
        else:
            self.score = -max_score

    fn best_move(self, out result: Game.Move):
        debug_assert(len(self.children) > 0, "Function node.best_move() is called with no children.")
        var has_draw = False
        var draw_move = self.children[-1].move
        var best_child = Pointer(to = self.children[-1])
        for ref child in self.children:
            if child.decision == Decision.loss:
                continue
            if child.decision == Decision.win:
                return child.move
            if child.decision == Decision.draw:
                has_draw = True
                draw_move = child.move
            if best_child[].n_sims < child.n_sims:
                best_child = Pointer(to = child)
        if has_draw and best_child[].score < Self.Score(0):
            return draw_move
        result = best_child[].move

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        if self.decision == Decision.undecided:
            writer.write("|   " * depth, self.move, " v: ", self.score, " s: ", self.n_sims, "\n")
        else:
            writer.write("|   " * depth, self.move, " d: ", self.decision, "\n")
        if self.children:
            for child in self.children:
                child.write_to(writer, depth + 1)
