from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore

alias debug = env_get_int["DEBUG2", 0]()


struct NegamaxZero[G: TGame](TTree):
    alias Game = G

    var _tree: Node[G]

    fn __init__(out self):
        var root = MoveScore[G.Move](G.Move(), score.Score(0))
        self._tree = Node[G](root, 0)
        self._tree.bounds = Bounds()

    fn search(mut self, mut game: G, duration_ms: Int) -> MoveScore[G.Move]:
        self = Self()
        var deadline = perf_counter_ns() + 1_000_000 * duration_ms
        var best_move = MoveScore[G.Move](G.Move(), score.Score(0))
        var max_depth = 1
        var guess: Score = 0

        var start = perf_counter_ns()
        while not guess.is_decisive():
            if debug > 1:
                self.print_tree()
            guess = self.mtdf(game, guess, max_depth, deadline)

            if perf_counter_ns() >= deadline:
                break

            var move = self._tree.children[0].move
            var score = self._tree.children[0].bounds.lower
            for child in self._tree.children:
                if child.bounds.lower > score:
                    score = child.bounds.lower
                    move = child.move
            best_move = MoveScore(move, score)

            print("<<< mtdf move:", best_move, "depth:", max_depth, "time", Float64(perf_counter_ns() - start) / 1_000_000)
            max_depth += 1

        print("total time", Float64(perf_counter_ns() - start) / 1_000_000)

        return best_move

    fn mtdf(mut self, mut game: G, var guess: Score, max_depth: Int, deadline: UInt) -> Score:
        self._tree.bounds = Bounds()
        while perf_counter_ns() < deadline:
            if debug > 0:
                print("\n>>> mtdf: max-depth:", max_depth, "guess:", guess, self._tree.bounds)
            if debug > 1:
                self.print_tree()

            self._tree.negamax_zero(game, guess, 0, max_depth, deadline)
            if debug > 0:
                if perf_counter_ns() >= deadline:
                    print("-- timeout --")
                print("root", self._tree, "guess", guess, "max-depth", max_depth)
                for child in self._tree.children:
                    print("  child", child)

            if self._tree.bounds.upper < guess:
                guess = self._tree.bounds.upper
            else:
                guess = self._tree.bounds.lower

            if self._tree.bounds.lower == self._tree.bounds.upper:
                break

        return guess

    fn print_tree(self):
        self._tree.print_tree()


@fieldwise_init
struct Bounds(Copyable, Defaultable, Movable, Stringable, Writable):
    var lower: Score
    var upper: Score

    fn __init__(out self):
        self.lower = Score.loss()
        self.upper = Score.win()

    fn is_decisive(self) -> Bool:
        return self.lower.is_decisive() and self.lower == self.upper

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self.lower == self.upper:
            writer.write("score: ", self.lower)
        else:
            writer.write("bounds: (", self.lower, " : ", self.upper, ")")


struct Node[G: TGame](Copyable, Movable, Stringable, Writable):
    var move: G.Move
    var bounds: Bounds
    var max_depth: Int
    var children: List[Self]

    fn __init__(out self, move: MoveScore[G.Move], depth: Int):
        self.move = move.move
        self.bounds = Bounds(move.score, move.score)
        self.max_depth = depth
        self.children = List[Self]()

    fn negamax_zero(mut self, mut game: G, guess: Score, depth: Int, max_depth: Int, deadline: UInt):
        @parameter
        fn greater(a: Self, b: Self) -> Bool:
            if a.bounds.lower > b.bounds.lower:
                return True
            if a.bounds.lower < b.bounds.lower:
                return False
            return a.bounds.upper > b.bounds.upper

        if deadline < perf_counter_ns():
            return

        if depth < max_depth and not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0)
            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Self(move, depth + 1))
        sort[greater](self.children)

        if depth + 1 == max_depth:
            self.max_depth = max_depth
            self.bounds = Bounds()
            for ref child in self.children:
                self.bounds.upper = min(self.bounds.upper, -child.bounds.lower)
                child.max_depth = max_depth
                if debug > 1:
                    print("|   " * depth + "== leaf", child)
            self.bounds.lower = self.bounds.upper
            return

        for ref child in self.children:
            if debug > 1:
                print("|   " * depth + ">", depth, child)

            if child.max_depth == max_depth and child.bounds.lower == child.bounds.upper:
                self.bounds.upper = min(self.bounds.upper, -child.bounds.lower)
                if debug > 1:
                    print("|   " * depth + "< skip")
                continue
            if child.bounds.lower < child.bounds.upper or not child.bounds.lower.is_decisive():
                child.bounds = Bounds()
                _ = game.play_move(child.move)
                child.negamax_zero(game, -guess, depth + 1, max_depth, deadline)
                game.undo_move(child.move)

            child.max_depth = max_depth
            self.bounds.upper = min(self.bounds.upper, -child.bounds.lower)

            if self.bounds.upper < guess:
                if debug > 1:
                    print("|   " * depth + "<", depth, "cut-off", child)
                return
            elif debug > 1:
                print("|   " * depth + "<", depth, child)

        self.bounds.lower = Score.win()
        for child in self.children:
            self.bounds.lower = min(self.bounds.lower, -child.bounds.upper)

        return

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("move: ", self.move, "; ", self.bounds, "; depth: ", self.max_depth)

    fn print_tree(self):
        self.print_tree(0)

    fn print_tree(self, depth: Int):
        print("|   " * depth + String(self))
        if self.children:  # this is to prevent Mojo warning
            for child in self.children:
                child.print_tree(depth + 1)


from connect6 import Connect6
from negamax import Negamax


fn main() raises:
    alias Game = Connect6[size=19, max_moves=8, max_places=6, max_plies=100]
    var game1 = Game()
    var game2 = Game()
    var tree1 = NegamaxZero[Game]()
    var tree2 = Negamax[Game]()
    _ = game1.play_move("j10")
    _ = game1.play_move("i9-i10")
    _ = game2.play_move("j10")
    _ = game2.play_move("i9-i10")
    while True:
        var move1 = tree1.search(game1, 1000)
        print("zero", move1)
        print("----")
        var move2 = tree2.search(game2, 1000)
        print("nmax", move2)

        _ = game1.play_move(move2.move)
        var result = game2.play_move(move2.move)
        print(game2)

        if result.is_decisive():
            break
