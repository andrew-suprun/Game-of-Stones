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
        var max_depth = 1
        var guess: Score = 0

        while perf_counter_ns() < deadline:
            guess = self.mtdf(game, guess, max_depth, deadline)
            max_depth += 1

        return self._best_move

    fn mtdf(mut self, mut game: G, var guess: Score, max_depth: Int, deadline: UInt) -> Score:
        if debug:
            print("\n====\n\n>> mtdf: guess", guess, "max_depth", max_depth)
        var upper_bound = Score.win()
        var lower_bound = Score.loss()

        while lower_bound < upper_bound:
            if debug:
                print(">> bounds:", lower_bound, "..", upper_bound)
            var beta = max(guess, lower_bound)
            guess = self._tree.negamax_zero(game, guess, 0, max_depth, deadline)
            if guess <= beta:
                upper_bound = guess
            if guess >= beta:
                lower_bound = guess
            if debug:
                print("<< bounds:", lower_bound, "..", upper_bound)

        if debug:
            print("<< mtdf: guess", guess, "best move", self._best_move.move)
        return guess


struct Node[G: TGame](Copyable, Movable):
    var move: G.Move
    var score: Score
    var max_depth: Int
    var children: List[Self]

    fn __init__(out self, move: MoveScore[G.Move], max_depth: Int):
        self.move = move.move
        self.score = move.score
        self.max_depth = max_depth
        self.children = List[Self]()

    fn negamax_zero(mut self, mut game: G, guess: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        @parameter
        fn greater(a: Self, b: Self) -> Bool:
            return a.score > b.score

        if deadline < perf_counter_ns():
            return 0

        if self.max_depth == max_depth and self.children:
            return self.score
        
        # if depth == max_depth:
        #     var move = game.move()
        #     if debug:
        #         print("|   " * depth, "leaf:", move)
        #     return move.score

        if not self.children:
            var moves = game.moves()
            debug_assert(len(moves) > 0)
            self.children.reserve(len(moves))
            for move in moves:
                self.children.append(Self(move, max_depth))

        debug_assert(len(self.children) > 0)
    
        if depth == max_depth:
            ...

        var best_score = Score.loss()

        sort[greater](self.children)

        for ref child in self.children:
            if debug:
                print("|   " * depth + "> move", child.move)
            if not child.score.is_decisive():
                _ = game.play_move(child.move)
                child.score = -self.negamax_zero(game, -guess, depth + 1, max_depth, deadline)
                game.undo_move(child.move)

            if child.score > best_score:
                best_score = child.score
                if depth == 0:
                    if debug:
                        print("### best move", child.move)

            if debug:
                print("|   " * depth + "< move", child.move, best_score)
            if child.score > guess:
                if debug:
                    print("|   " * depth + "cut-off:", child.score, ">", guess)
                return best_score

        return best_score
