from math import log2, sqrt
from memory import Pointer

from game import TGame, Score

struct Tree[Game: TGame, c: Score](Stringable, Writable):
    var root: Node[Game, c]

    fn __init__(out self):
        self.root = Node[Game, c](Game.Move())
        
    fn expand(mut self, game: Game, out done: Bool):
        if self.root.move.score().isdecisive():
            return True
        else:
            var g = game
            self.root._expand(g)
        
        if self.root.move.score().isdecisive():
            return True

        var undecided = 0
        for child in self.root.children:
            if not child.move.score().isdecisive():
                undecided += 1
        return undecided == 1

    fn score(self) -> Score:
        return -self.root.move.score()
        
    fn best_move(self) -> Game.Move:
        return self.root.best_move()
        
    fn principal_variation(self) -> List[Game.Move]:
        var result = List[Game.Move]()
        self.root._principal_variation(result)
        return result
        
    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.root.write_to(writer)

    fn debug_best_moves(self):
        for ref node in self.root.children:
            print("  ", node.move, node.move.score(), node.n_sims)

@fieldwise_init
struct Node[Game: TGame, c: Score](Copyable, Movable, Representable, Stringable, Writable):
    var move: Game.Move
    var children: List[Self]
    var n_sims: Int32

    fn __init__(out self, move: Game.Move):
        self.move = move
        self.children = List[Self]()
        self.n_sims = 1

    fn _expand(mut self, mut game: Game):
        if not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0, "Function moves(...) returns empty result.")

            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Node[Game, c](move))
                if move.score().isdecisive():
                    continue
            for ref child_node in self.children:
                var child_game = game
                child_game.play_move(child_node.move)
                var child_moves = child_game.moves()
                child_node.children.reserve(len(child_moves))
                for child_move in child_moves:
                    child_node.children.append(Node[Game, c](child_move))
                child_node._update_states()
        else:
            var selected_child_idx = 0
            var log_parent_sims = log2(Float32(self.n_sims))
            var maxV = Score.loss()
            for child_idx in range(len(self.children)):
                ref child = self.children[child_idx]
                if child.move.score().iswin():
                    continue
                var v = child.move.score() + self.c * Score(sqrt(log_parent_sims / Float32(child.n_sims)))
                if maxV < v:
                    maxV = v
                    selected_child_idx = child_idx
            ref selected_child = self.children[selected_child_idx]
            game.play_move(selected_child.move)
            selected_child._expand(game)
        self._update_states()

    fn _update_states(mut self):
        self.n_sims = 0
        var max_score = Score.loss()
        var all_draws = True
        var has_draw = False
        for child in self.children:
            self.n_sims += child.n_sims
            if child.move.score().isloss():
                continue
            elif child.move.score().iswin():
                self.move.setscore(Score.loss())
                return
            elif child.move.score().isdraw():
                has_draw = True
                max_score = max_score.max(Score())
                continue
            all_draws = False
            max_score = max_score.max(child.move.score())
        if has_draw and all_draws:
            self.move.setscore(Score.draw())
        else:
            self.move.setscore(-max_score)

    # fn best_move(self, out result: Game.Move):
    #     debug_assert(len(self.children) > 0, "Function node.best_move() is called with no children.")
    #     var best_child = Pointer(to = self.children[-1])
    #     for ref child in self.children:
    #         if best_child[].move.score() < child.move.score():
    #             best_child = Pointer(to = child)
    #     result = best_child[].move

    fn best_move(self, out result: Game.Move):
        debug_assert(len(self.children) > 0, "Function node.best_move() is called with no children.")
        var has_draw = False
        var draw = self.children[-1].move
        var best_child = Pointer(to = self.children[-1])
        for ref child in self.children:
            if child.move.score().isloss():
                continue
            if child.move.score().iswin():
                return child.move
            if child.move.score().isdraw():
                has_draw = True
                draw = child.move
            if best_child[].n_sims < child.n_sims:
                best_child = Pointer(to = child)
        if has_draw and best_child[].move.score() < 0:
            return draw
        result = best_child[].move

    fn _principal_variation(self, mut result: List[Game.Move]):
        var value = self.move.score().value()
        for ref child_node in self.children:
            if child_node.move.score().value() == -value:
                result.append(child_node.move)
                child_node._principal_variation(result)
                return

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, 0)

    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self.move, " v: ", self.move.score(), " s: ", self.n_sims, "\n")
        if self.children:
            for child in self.children:
                child.write_to(writer, depth + 1)
