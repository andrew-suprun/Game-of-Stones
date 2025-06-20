from math import log2, sqrt
from memory import Pointer

from game import TGame

struct Tree[Game: TGame, c: Game.Move.Score](Stringable, Writable):
    var root: Node[Game, c]
    var top_moves: List[Game.Move]

    fn __init__(out self):
        self.root = Node[Game, c](Game.Move())
        self.top_moves = List[Game.Move]()

    fn expand(mut self, game: Game, out done: Bool):
        if self.root.move.score().is_decisive():
            return True
        else:
            var g = game
            self.root._expand(g, self.top_moves)
        
        if self.root.move.score().is_decisive():
            return True

        var undecided = 0
        for child in self.root.children:
            if not child.move.score().is_decisive():
                undecided += 1
        return undecided == 1

    fn score(self) -> Game.Move.Score:
        return -self.root.move.score()
        
    fn best_move(self) -> Game.Move:
        return self.root.best_move()
        
    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.root.write_to(writer, 0)

    fn debug_print_root_children(self):
        self.root.debug_print_root_children()

@fieldwise_init
struct Node[Game: TGame, c: Game.Move.Score](Copyable, Movable, Stringable, Writable):
    var move: Game.Move
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: Game.Move):
        self.move = move
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, mut game: Game, mut top_moves: List[Game.Move]):
        alias Score = Game.Move.Score

        if not self.children:
            var top_moves = game.top_moves()
            debug_assert(len(top_moves) > 0, "Function top_moves(...) returns empty result.")

            self.children.reserve(len(top_moves))
            for move in top_moves:
                self.children.append(Node[Game, c](move))
        else:
            ref selected_child = self.children[0]
            var n_sims = self.n_sims
            var log_parent_sims = log2(Float32(n_sims))
            var maxV = Score.loss().value()
            for ref child in self.children:
                if child.move.score().is_win():
                    continue
                var v = child.move.score().value() + self.c.value() * sqrt(log_parent_sims / Float32(child.n_sims))
                if maxV < v:
                    maxV = v
                    selected_child = child
            var move = selected_child.move
            game.play_move(move)
            selected_child._expand(game, top_moves)
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

    fn __str__(self, out result: String):
        result = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.move, " v: ", self.move.score(), " s: ", self.n_sims)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self, "\n")
        if self.children:
            for ref child in self.children:
                child.write_to(writer, depth + 1)

    fn debug_print_root_children(self):
        print(self)
        for child in self.children:
            print("  ", child)
