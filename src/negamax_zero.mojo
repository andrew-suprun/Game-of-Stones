from sys import env_get_bool
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore

alias debug = env_get_bool["DEBUG", False]()

struct NegamaxZero[G: TGame](TTree):
    alias Game = G

    var _best_move: MoveScore[G.Move]
    var _deadline: UInt

    fn __init__(out self):
        self._best_move = MoveScore[G.Move](G.Move(), score.Score(0))
        self._deadline = 0

    fn search(mut self, mut game: G, duration_ms: Int) -> MoveScore[G.Move]:
        self._deadline = perf_counter_ns() + 1_000_000 * duration_ms
        self._best_move = game.move()
        var max_depth = 1
        var guess: Score = 0

        while perf_counter_ns() < self._deadline:
            guess = self.mtdf(game, guess, max_depth)
            max_depth += 1

        return self._best_move

    fn mtdf[Game: TGame](mut self, mut game: Game, var guess: Score, max_depth: Int) -> Score:
        if debug:
            print("\n====\n\n>> mtdf: guess", guess, "max_depth", max_depth)
        var upper_bound = Score.win()
        var lower_bound = Score.loss()

        while lower_bound < upper_bound:
            if debug:
                print(">> bounds:", lower_bound, "..", upper_bound)
            var beta = max(guess, lower_bound)
            guess = self.negamax_zero(game, guess, 0, max_depth)
            if guess <= beta:
                upper_bound = guess
            if guess >= beta:
                lower_bound = guess
            if debug:
                print("<< bounds:", lower_bound, "..", upper_bound)

        if debug:
            print("<< mtdf: guess", guess, "best move", self._best_move.move)
        return guess


    fn negamax_zero[Game: TGame](mut self, mut game: Game, guess: Score, depth: Int, max_depth: Int) -> Score:
        @parameter
        fn greater(a: MoveScore[Game.Move], b: MoveScore[Game.Move]) -> Bool:
            return a.score > b.score

        if self._deadline < perf_counter_ns():
            return 0
        
        if depth == max_depth:
            var move = game.move()
            if debug:
                print("|   " * depth, "leaf:", move)
            return move.score

        var children = game.moves()

        debug_assert(len(children) > 0)

        var best_score = Score.loss()

        sort[greater](children)

        for ref child in children:
            if debug:
                print("|   " * depth + "> move", child.move)
            if not child.score.is_decisive():
                _ = game.play_move(child.move)
                child.score = -self.negamax_zero(game, -guess, depth + 1, max_depth)
                game.undo_move(child.move)

            if child.score > best_score:
                best_score = child.score
                if depth == 0:
                    if debug:
                        print("### best move", child)

            if debug:
                print("|   " * depth + "< move", child.move, best_score)
            if child.score > guess:
                if debug:
                    print("|   " * depth + "cut-off:", child.score, ">", guess)
                return best_score

        return best_score
