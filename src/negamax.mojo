from sys import env_get_bool
from time import perf_counter_ns

from score import Score
from game import TGame, MoveScore
from tree import TTree

alias debug = env_get_bool["DEBUG", False]()


struct Negamax[G: TGame](TTree):
    alias Game = G

    var _best_move: MoveScore[G.Move]
    var _deadline: UInt
    var _moves_cache: Dict[Int, List[MoveScore[G.Move]]]

    fn __init__(out self):
        self._best_move = MoveScore[G.Move](G.Move(), score.Score(0))
        self._deadline = 0
        self._moves_cache = Dict[Int, List[MoveScore[G.Move]]]()

    fn search(mut self, mut game: G, duration_ms: Int) -> MoveScore[G.Move]:
        var moves = game.moves()
        debug_assert(len(moves) > 0)
        if len(moves) == 1:
            return moves[0]
        var all_draws = True
        for move in moves:
            if move.score.is_win():
                return move
            if not move.score.is_draw():
                all_draws = False
        if all_draws:
            return moves[0]

        self._deadline = perf_counter_ns() + 1_000_000 * duration_ms
        self._moves_cache.clear()
        self._best_move = game.move()
        var max_depth = 0

        var start = perf_counter_ns()
        while True:
            var result = self._search(game, Score.loss(), Score.win(), 0, max_depth)
            if perf_counter_ns() >= self._deadline:
                break
            print("<<< nmax move:", self._best_move, "depth:", max_depth + 1, "time", Float64(perf_counter_ns() - start) / 1_000_000)
            if debug:
                print("nmax move:", self._best_move, "depth:", max_depth + 1, "time", Float64(perf_counter_ns() - start) / 1_000_000)
            if result.is_decisive():
                break
            max_depth += 1
        return self._best_move

    fn _search(mut self, mut game: G, var alpha: score.Score, beta: score.Score, depth: Int, max_depth: Int) -> score.Score:
        @parameter
        fn greater(a: MoveScore[G.Move], b: MoveScore[G.Move]) -> Bool:
            return a.score > b.score

        if debug:
            print("#" + "|   " * depth + "--> search: depth", depth, "max_depth", max_depth)

        if depth == max_depth:
            var move = game.move()
            if debug:
                print("#" + "|   " * depth + "leaf:", move)
            return move.score

        var children: List[MoveScore[G.Move]]
        try:
            children = self._moves_cache[game.hash()]
        except:
            children = game.moves()

        debug_assert(len(children) > 0)

        var best_score = Score.loss()

        sort[greater](children)

        for ref child in children:
            if debug:
                print("#" + "|   " * depth + ">", child.move, child.score)
            if not child.score.is_decisive():
                _ = game.play_move(child.move)
                child.score = -self._search(game, -beta, -alpha, depth + 1, max_depth)
                game.undo_move(child.move)
                if perf_counter_ns() > self._deadline:
                    if debug:
                        print("#" + "|   " * depth + "<-- search: timeout")
                    return score.Score(0)

            if child.score > best_score:
                best_score = child.score
                if child.score > alpha:
                    alpha = child.score

                if depth == 0:
                    self._best_move = child
                    if debug:
                        print("#|   set best move", child)

            if debug:
                print("#" + "|   " * depth + "<", child.move, child.score, "| best score", best_score)
            if child.score > beta:
                if debug:
                    print("#" + "|   " * depth + "cutoff")
                return best_score

        self._moves_cache[game.hash()] = children^
        if debug:
            print("#" + "|   " * depth + "<-- search: best score", best_score)
        return best_score
