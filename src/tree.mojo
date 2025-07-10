from memory import Pointer
from utils.numerics import neg_inf

from game import TGame

struct Tree[Game: TGame, c: Float64](Stringable, Writable):
    var roots: List[Node[Game, c]]
    var no_moves_score: Game.Score

    fn __init__(out self, no_moves_score: Game.Score):
        self.roots = List[Node[Game, c]]()
        self.no_moves_score = no_moves_score
        
    fn expand(mut self, game: Game, out done: Bool):
        if not self.roots:
            var moves = game.moves()
            self.roots.reserve(len(moves))
            for move in moves:
                self.roots.append(Node[Game, c](move))
            return False

        var n_sims = Int32(0)
        for ref root in self.roots:
            n_sims += root.n_sims

        var selected_idx = Node.select_node(self.roots, self.c * Float64(n_sims))
        ref root = self.roots[selected_idx]

        if root.score.isdecisive():
            return True
        else:
            var g = game
            g.play_move(root.move)
            root._expand(g)

        
        var undecided = 0
        for ref root in self.roots:
            if not root.score.isdecisive():
                undecided += 1
        return undecided < 2

    fn best_move(self, out result: Game.Move):
        debug_assert(len(self.roots) > 0, "Function node.best_move() is called with no children.")
        var has_draw = False
        var draw_move = self.roots[-1].move
        var best_child = Pointer(to = self.roots[-1])
        for ref child in self.roots:
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

    fn write_to[W: Writer](self, mut writer: W):
        for ref root in self.roots:
            root.write_to(writer)

    fn debug_roots(self):
        print("roots")
        for ref node in self.roots:
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
            if not moves:
                self.score = Game.Score.draw()
                return

            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Node[Game, c](move))
        else:
            var exp_factor = self.c * Float64(self.n_sims)
            ref selected_child = self.children[Self.select_node(self.children, exp_factor)]
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

    @staticmethod
    fn select_node(nodes: List[Node[Game, c]], exp_factor: Float64) -> Int:
        var selected_child_idx = 0
        var maxV = neg_inf[DType.float64]()
        for child_idx in range(len(nodes)):
            ref child = nodes[child_idx]
            if child.score.isdecisive():
                continue
            var v = Float64(child.score) + exp_factor / Float64(child.n_sims)
            if maxV < v:
                maxV = v
                selected_child_idx = child_idx
        return selected_child_idx


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
