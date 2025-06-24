from math import log2, sqrt
from memory import Pointer

from game import TGame

struct Tree[Game: TGame, c: Game.Move.Score](Stringable, Writable):
    var root: Node[Game, c]

    fn __init__(out self):
        self.root = Node[Game, c](Game.Move())
        
    fn expand(mut self, game: Game, out done: Bool):
        if self.root.move.score().is_decisive():
            return True
        else:
            var g = game
            self.root._expand(g)
        
        if self.root.move.score().is_decisive():
            return True

        var undecided = 0
        for child in self.root.children:
            if not child.move.score().is_decisive():
                undecided += 1
        return undecided == 1

    fn score(self) -> Game.Move.Score:
        return self.root.move.score()
        
    fn best_move(self) -> Game.Move:
        return self.root.best_move()
        
    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.root.write_to(writer)

@fieldwise_init
struct Node[Game: TGame, c: Game.Move.Score](Copyable, Movable, Representable, Stringable, Writable):
    var move: Game.Move
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: Game.Move):
        self.move = move
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, mut game: Game):
        alias Score = Game.Move.Score

        if not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0, "Function moves(...) returns empty result.")

            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Node[Game, c](move))
            for ref child_node in self.children:
                var child_game = game
                child_game.play_move(child_node.move)
                var child_moves = child_game.moves()
                child_node.children.reserve(len(child_moves))
                for child_move in child_moves:
                    child_node.children.append(Node[Game, c](child_move))
                child_node._update_state()
        else:
            var selected_child_idx = 0
            var log_parent_sims = log2(Float32(self.n_sims))
            var maxV = Score.loss().value()
            for child_idx in range(len(self.children)):
                var child = self.children[child_idx]
                if child.move.score().is_win():
                    continue
                var v = child.move.score().value() + self.c.value() * sqrt(log_parent_sims / Float32(child.n_sims))
                if maxV < v:
                    maxV = v
                    selected_child_idx = child_idx
            ref selected_child = self.children[selected_child_idx]
            game.play_move(selected_child.move)
            selected_child._expand(game)
        self._update_state()

    fn _update_state(mut self):
        alias Score = Game.Move.Score

        self.n_sims = 0
        var score = Score.win()
        var has_draw = False
        var all_draws = True
        for child in self.children:
            if child.move.score().is_win():
                self.move.set_score(Score.loss())
                return
            elif child.move.score().is_draw():
                has_draw = True
                continue
            all_draws = False
            if child.move.score().is_loss():
                continue
            self.n_sims += child.n_sims
            var child_score = child.move.score()
            score = score.min(-child_score)
        if all_draws:
            self.move.set_score(Score.draw())
        elif has_draw:
            self.move.set_score(self.move.score().min(Score()))
        else:
            self.move.set_score(score)

    fn best_move(self, out result: Game.Move):
        debug_assert(len(self.children) > 0, "Function node.best_move() is called with no children.")
        var best_child = Pointer(to = self.children[0])
        for child in self.children:
            if best_child[].move.score() < child.move.score():
                best_child = Pointer(to = child)
            elif best_child[].move.score().is_loss() and best_child[].n_sims < child.n_sims:
                best_child = Pointer(to = child)
        result = best_child[].move

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self.move, " v: ", self.move.score(), " s: ", self.n_sims, "\n")
        if self.children:
            for ref child in self.children:
                child.write_to(writer, depth + 1)
