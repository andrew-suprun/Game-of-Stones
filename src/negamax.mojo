from builtin.debug_assert import ASSERT_MODE
from builtin.sort import sort
from utils.numerics import inf, neg_inf

from game import TGame, Score

struct Negamax[Game: TGame](Defaultable):
    var best_move: Game.Move
    var _max_depth: Int

    fn __init__(out self):
        self.best_move = Game.Move()
        self._max_depth = 0

    fn expand(mut self, mut game: Game, max_depth: Int) -> Score:
        self._max_depth = max_depth
        var score = self._expand(game, neg_inf[DType.float32](), inf[DType.float32](), 0)
        if ASSERT_MODE == "all":
            print()
        return score

    fn _expand(mut self, mut game: Game, alpha: Score, beta: Score, depth: Int) -> Score:
        var a = alpha
        var b = beta
        if depth == self._max_depth:
            var move = game.best_move()
            if ASSERT_MODE == "all":
                print("\n" + "|   "*depth + "leaf: best move", move, end="")
            return move.score()

        if ASSERT_MODE == "all":
            print("\n" + "|   "*depth + "--> expand:", "a:", alpha, "b:", beta, end="")
        var best_score = neg_inf[DType.float32]()
        var moves = game.moves()
        sort[Self.greater](moves)

        if ASSERT_MODE == "all":
            print(" | moves: ", sep="", end="")
            for move in moves:
                print(move, "  ", end="")

        for ref child_move in moves:
            if ASSERT_MODE == "all":
                print("\n" + "|   "*depth + "> move", child_move, end="")
            var score = child_move.score()
            if not child_move.is_terminal():
                game.play_move(child_move)
                score = -self._expand(game, -b, -a, depth + 1)
                game.undo_move(child_move)

            if score > best_score:
                if depth == 0:
                    self.best_move = child_move
                    if ASSERT_MODE == "all":
                        print("\n" + "|   "*depth + "set best move", child_move, "score", score, end="")
                best_score = score
                if score > alpha:
                    a = score
            if ASSERT_MODE == "all":
                print("\n" + "|   "*depth + "< move", child_move, "| best score", best_score,end="")
            if score > b:
                if ASSERT_MODE == "all":
                    print("\n" + "|   "*depth + "cutoff", end="")
                return best_score
        if ASSERT_MODE == "all":
            print("\n" + "|   "*depth + "<-- expand: best score", best_score, end="")
        return best_score

    @parameter
    @staticmethod
    fn greater(a: Game.Move, b: Game.Move) capturing -> Bool:
        return a.score() > b.score()