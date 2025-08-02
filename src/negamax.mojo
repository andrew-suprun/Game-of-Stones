from builtin.debug_assert import ASSERT_MODE
from utils.numerics import inf, neg_inf

from game import TGame, Score

struct Negamax[Game: TGame, max_moves: Int](Defaultable):
    var best_move: Game.Move
    var _max_depth: Int

    fn __init__(out self):
        self.best_move = Game.Move()
        self._max_depth = 0

    fn expand(mut self, game: Game, max_depth: Int) -> (Score, List[Game.Move]):
        self._max_depth = max_depth
        var (score, pv) = self._expand(game, neg_inf[DType.float32](), inf[DType.float32](), 0)
        if ASSERT_MODE == "all":
            print()
        return (score, pv)

    fn _expand(mut self, game: Game, alpha: Score, beta: Score, depth: Int) -> (Score, List[Game.Move]):
        var a = alpha
        var b = beta
        if depth == self._max_depth:
            var moves = game.moves(1)
            if ASSERT_MODE == "all":
                print("\n" + "|   "*depth + "leaf: best move", moves[0], end="")
            return (moves[0].score(), [moves[0]])

        if ASSERT_MODE == "all":
            print("\n" + "|   "*depth + "--> expand:", "a:", alpha, "b:", beta, end="")
        var best_score = neg_inf[DType.float32]()
        var best_pv = List[Game.Move]()
        var best_move = Game.Move()
        var moves = game.moves(max_moves)

        if ASSERT_MODE == "all":
            print(" | moves: ", sep="", end="")
            for ref child_move in moves:
                print(child_move, "  ", end="")

        for ref child_move in moves:
            if ASSERT_MODE == "all":
                print("\n" + "|   "*depth + "> move", child_move, end="")
            var score = child_move.score()
            if not child_move.is_terminal():
                var child_game = game
                child_game.play_move(child_move)
                (score, pv) = self._expand(child_game, -b, -a, depth + 1)
                score = -score
            else:
                pv = List[Game.Move]()

            if score > best_score:
                if depth == 0:
                    self.best_move = child_move
                    if ASSERT_MODE == "all":
                        print("\n|   set best move", child_move, "score", score, end="")
                        print(" pv: ", end="")
                        for move in pv[::-1]:
                            print(move, "| ", end="")

                best_score = score
                best_pv = pv
                best_move = child_move
                if score > alpha:
                    a = score
            if ASSERT_MODE == "all":
                print("\n" + "|   "*depth + "< move", child_move, "| best score", best_score,end="")
            if score > b:
                if ASSERT_MODE == "all":
                    print("\n" + "|   "*depth + "cutoff", end="")
                return (best_score, List[Game.Move]())
        if ASSERT_MODE == "all":
            print("\n" + "|   "*depth + "<-- expand: best score", best_score, end="")
        best_pv.append(best_move)
        return (best_score, best_pv)

