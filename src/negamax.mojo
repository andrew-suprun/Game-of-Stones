from builtin.debug_assert import ASSERT_MODE
from builtin.sort import sort

from game import TGame, Score, win, loss

struct Negamax[Game: TGame](Defaultable):
    var best_move: Game.Move
    var _max_depth: Int

    fn __init__(out self):
        self.best_move = Game.Move()
        self._max_depth = 0

    fn expand(mut self, mut game: Game, max_depth: Int) -> Score:
        self._max_depth = max_depth
        var score = self._expand(game, loss, win, 0)
        if ASSERT_MODE == "all":
            print()
        return score

    fn _expand(mut self, mut game: Game, alpha: Score, beta: Score, depth: Int) -> Score:
        var a = alpha
        var b = beta
        if depth == self._max_depth:
            var score = game.best_score()
            if ASSERT_MODE == "all":
                print(" score", -score, end="")
            return score
        else:
            if ASSERT_MODE == "all":
                print("\n" + "|   "*depth + "--> expand:", "a:", alpha, "b:", beta, end="")
        var best_score = loss
        var moves = game.moves()

        sort[grater[Game]](moves)

        if ASSERT_MODE == "all":
            print("\n" + "|   "*depth + "moves (", len(moves), "): ", sep="", end="")
            for move in moves:
                print(move[0], "", end="")

        for (child_move, _) in moves:
            if ASSERT_MODE == "all":
                print("\n" + "|   "*depth + "move", child_move, end="")
            game.play_move(child_move)
            var score = -self._expand(game, -b, -a, depth + 1)
            game.undo_move(child_move)
            if score > best_score:
                if depth == 0:
                    self.best_move = child_move
                    if ASSERT_MODE == "all":
                        print("\n" + "|   "*depth + "set best move", child_move, end="")
                best_score = score
                if score > alpha:
                    a = score
            if score > b:
                if ASSERT_MODE == "all":
                    print("\n" + "|   "*depth + "cutoff", child_move, end="")
                    print("\n" + "|   "*depth + "<-- expand: score", best_score, end="")
                return best_score
        if ASSERT_MODE == "all":
            print("\n" + "|   "*depth + "<-- expand: score", best_score, end="")
        return best_score

fn grater[Game: TGame](a: (Game.Move, Score), b: (Game.Move, Score)) capturing -> Bool:
    return a[1] > b[1]