from sys import env_get_bool
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore

alias debug = env_get_bool["DEBUG", False]()

struct NegamaxZero[G: TGame](TTree):
    alias Game = G

    var _tree: Node[G]
    var _best_move: MoveScore[G.Move]

    fn __init__(out self):
        var root = MoveScore[G.Move](G.Move(), score.Score(0))
        self._tree = Node[G](root, 0)
        self._best_move = root

    fn search(mut self, mut game: G, duration_ms: Int) -> MoveScore[G.Move]:
        var deadline = perf_counter_ns() + 1_000_000 * duration_ms
        self._best_move = game.move()
        print("@@@>>>>", self._best_move, "\n")
        var max_depth = 1
        var guess: Score = 0

        while perf_counter_ns() < deadline and not guess.is_win() and not guess.is_loss():
            guess = self.mtdf(game, guess, max_depth, deadline)
            max_depth += 1

        print("\n\n@@@<<<<", self._best_move, "\n")

        return self._best_move

    fn mtdf(mut self, mut game: G, var guess: Score, max_depth: Int, deadline: UInt) -> Score:
        if debug:
            print("\n====\n\n>> mtdf: guess", guess, "max_depth", max_depth)
        print("\n====\n\n>> mtdf: guess", guess, "max_depth", max_depth)

        var bounds = Bounds()
        while bounds.lower < bounds.upper:
            if debug:
                print("### ", bounds)
            print(">> guess:", guess, bounds)
            for child in self._tree.children:
                print("    child", child.move)

            bounds = self._tree.negamax_zero(game, guess, 0, max_depth, deadline)
            guess = max(guess, bounds.lower)
            guess = min(guess, bounds.upper)
        
        if perf_counter_ns() < deadline:
            var move = self._tree.children[0].move
            var score = self._tree.children[0].bounds.lower
            for child in self._tree.children:
                if child.bounds.lower > score:
                    score = child.bounds.lower
                    move = child.move
            self._best_move = MoveScore(move, score)
            print("### best move", move, "score", score)

        if debug:
            print("<< mtdf: guess", guess, "best move", self._best_move.move)
        print("<< bounds:", bounds.lower, "..", bounds.upper, "| guess", guess)
        print("<< mtdf: guess", guess, "best move", self._best_move.move)
        return guess


@fieldwise_init
struct Bounds(Copyable, Defaultable, Movable, Stringable, Writable):
    var lower: Score
    var upper: Score

    fn __init__(out self):
        self.lower = Score.loss()
        self.upper = Score.win()

    fn __neg__(self) -> Self:
        return Self(-self.upper, -self.lower)

    fn set_max(mut self, other: Self):
        self.lower = max(self.lower, other.lower)
        self.upper = max(self.upper, other.upper)

    fn is_decisive(self) -> Bool:
        return self.lower.is_decisive() and self.lower == self.upper

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self.lower == self.upper:
            writer.write("score: ", self.lower)
        else:
            writer.write("bounds: ", self.lower, "..", self.upper)



struct Node[G: TGame](Copyable, Movable, Stringable, Writable):
    var move: G.Move
    var bounds: Bounds
    var max_depth: Int
    var children: List[Self]

    fn __init__(out self, move: MoveScore[G.Move], max_depth: Int):
        self.move = move.move
        self.bounds = Bounds(move.score, move.score)
        self.max_depth = max_depth
        self.children = List[Self]()

    fn negamax_zero(mut self, mut game: G, guess: Score, depth: Int, max_depth: Int, deadline: UInt) -> Bounds:
        @parameter
        fn greater(a: Self, b: Self) -> Bool:
            if a.bounds.lower > b.bounds.lower:
                return True
            if a.bounds.lower < b.bounds.lower:
                return False
            return a.bounds.upper > b.bounds.upper

        if debug:
            print("|   " * depth + ">> guess", guess, "depth", depth, "max_depth", max_depth)

        if deadline < perf_counter_ns():
            if debug:
                print("|   " * depth + "<< deadline")
            return Bounds()

        if not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0)
            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Self(move, max_depth))
        
        sort[greater](self.children)

        if depth < max_depth:
            for ref child in self.children:
                if not child.bounds.is_decisive():
                    child.bounds = Bounds()

        if depth == max_depth:
            var max_bounds = Bounds(Score.loss(), Score.loss())
            for child in self.children:
                max_bounds.lower = max(max_bounds.lower, child.bounds.lower)
                max_bounds.upper = max(max_bounds.upper, child.bounds.upper)
                if debug:
                    print("|   " * depth + "  child", child.move, child.bounds)
            self.bounds = -max_bounds
            if debug:
                print("|   " * depth + "<< leaf:", self)
            return self.bounds


        var best_bounds = Bounds(Score.loss(), Score.loss())

        for ref child in self.children:
            if debug:
                print("|   " * depth + ">", child.move)
            if not child.bounds.is_decisive():
                _ = game.play_move(child.move)
                child.bounds = child.negamax_zero(game, -guess, depth + 1, max_depth, deadline)
                game.undo_move(child.move)

            best_bounds.set_max(child.bounds)

            if debug:
                print("|   " * depth + "<", child)
            if child.bounds.lower > guess:
                self.bounds = -best_bounds
                if debug:
                    print("|   " * depth + "<< cut-off:", child, "guess:", guess)
                return self.bounds

        self.bounds = -best_bounds
        if debug:
            print("|   " * depth + "<< move", self)

        return self.bounds

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("move: ", self.move, " ", self.bounds, " max depth: ", self.max_depth)
