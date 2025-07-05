from math import log2, sqrt
from memory import Pointer
from utils.numerics import neg_inf

from game import TGame, TMove, win, loss, draw, undecided

struct Tree[Game: TGame, c: Float64](Stringable, Writable):
    var root: Node[Game, c]

    fn __init__(out self):
        self.root = Node[Game, c](Game.Move(), 0)
        
    fn expand(mut self, game: Game, out done: Bool):
        if self.root.min_decision == self.root.max_decision:
            return True
        else:
            var g = game
            self.root._expand(g)
        
        if self.root.min_decision == self.root.max_decision:
            return True

        var undecided = 0
        for child in self.root.children:
            if child.min_decision != child.max_decision:
                undecided += 1

        return undecided == 1

    fn score(self) -> Float64:
        return -self.root.score()
        
    fn best_move(self) -> Game.Move:
        return self.root.best_move()
        
    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.root.write_to(writer)

    fn debug_best_moves(self):
        for ref node in self.root.children:
            var log_parent_sims = log2(Float64(self.root.n_sims))
            var v = node.score() + self.c * sqrt(log_parent_sims / Float64(node.n_sims))
            print("  ", node.move, node.score(), node.n_sims, v)

@fieldwise_init
struct Node[Game: TGame, c: Float64](Copyable, Movable, Representable, Stringable, Writable):
    var move: Game.Move
    var children: List[Self]
    var n_sims: Int32
    var value: Int32
    var min_decision: Int8
    var max_decision: Int8

    fn __init__(out self, move: Game.Move, value: Int32):
        self.move = move
        self.children = List[Self]()
        self.n_sims = 1
        self.value = value
        var decision = move.decision()
        if decision != undecided:
            self.min_decision = decision
            self.max_decision = decision
        else:
            self.min_decision = loss
            self.max_decision = win

    fn _expand(mut self, mut game: Game):
        if not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0, "Function moves(...) returns empty result.")

            self.children.reserve(len(moves))
            for move in moves:
                if move.decision() != undecided:
                    self.children.append(Node[Game, c](move, 0))
                    continue
                var rollout_game = game
                self.children.append(Node[Game, c](move, rollout_game.rollout(move)))
        else:
            var selected_child_idx = 0
            var log_parent_sims = log2(Float64(self.n_sims))
            var maxV: Float64 = neg_inf[DType.float64]()
            for child_idx in range(len(self.children)):
                ref child = self.children[child_idx]
                if child.min_decision == child.max_decision:
                    continue
                var v = child.score() + self.c * sqrt(log_parent_sims / Float64(child.n_sims))
                if maxV < v:
                    maxV = v
                    selected_child_idx = child_idx
            ref selected_child = self.children[selected_child_idx]
            game.play_move(selected_child.move)
            selected_child._expand(game)

        self.n_sims = 1
        self.value = 0
        var min_decision = Int8(loss)
        var max_decision = Int8(loss)
        for child in self.children:
            if min_decision < child.min_decision:
                min_decision = child.min_decision
            if max_decision < child.max_decision:
                max_decision = child.max_decision
            if child.min_decision != child.max_decision:
                self.n_sims += child.n_sims
                self.value -= child.value
        self.min_decision = -max_decision
        self.max_decision = -min_decision

    fn best_move(self, out result: Game.Move):
        debug_assert(len(self.children) > 0, "Function node.best_move() is called with no children.")
        var has_draw = False
        var draw_move = self.children[-1].move
        var best_child = Pointer(to = self.children[-1])
        var best_score = neg_inf[DType.float64]()
        for ref child in self.children:
            if child.max_decision == loss:
                continue
            if child.min_decision == draw:
                has_draw = True
                draw_move = child.move
            if child.min_decision == win:
                return child.move
            var child_score = child.score()
            if best_score < child_score:
                best_child = Pointer(to = child)
                best_score = child_score
        if has_draw and best_score < 0:
            return draw_move
        result = best_child[].move

    fn score(self) -> Float64:
        return Float64(self.value) / Float64(self.n_sims)

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        if self.min_decision == self.max_decision:
            writer.write("|   " * depth, self.move, " ", str_decision(self.min_decision), "\n")
        else:
            writer.write("|   " * depth, self.move, " v: ", self.score(), " s: ", self.n_sims)
            if self.min_decision == draw:
                writer.write(" min-draw\n")
            elif self.max_decision == draw:
                writer.write(" max-draw\n")
            else:
                writer.write("\n")
        if self.children:
            for child in self.children:
                child.write_to(writer, depth + 1)

fn str_decision(d: Int8) -> String:
    if d == win:
        return "win"
    if d == loss:
        return "loss"
    if d == draw:
        return "draw"
    return "undecided"