from sys import argv, env_get_bool
from time import perf_counter_ns

import score
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

    fn search(mut self, game: G, duration_ms: Int) -> MoveScore[G.Move]:
        self._deadline = perf_counter_ns() + 1_000_000 * duration_ms
        self._moves_cache.clear()
        self._best_move = game.move()
        var max_depth = 1

        while perf_counter_ns() < self._deadline:
            var result = self._search(game, score.Score.MIN, score.Score.MAX, 0, max_depth)
            if debug:
                print()
            if score.is_decisive(result):
                break
            max_depth += 1
        return self._best_move

    # TODO: var alpha
    fn _search(mut self, game: G, alpha: score.Score, beta: score.Score, depth: Int, max_depth: Int) -> score.Score:
        @parameter
        fn greater(a: MoveScore[G.Move], b: MoveScore[G.Move]) -> Bool:
            return a.score > b.score

        if debug:
            print("\n#" + "|   " * depth + "--> search: depth", depth, "max_depth", max_depth, end="")

        var a = alpha
        var b = beta
        if depth == max_depth:
            var move = game.move()
            if debug:
                print("\n#" + "|   " * depth + "leaf: move", move, end="")
            return move.score

        var children: List[MoveScore[G.Move]]
        try:
            children = self._moves_cache[game.hash()]
        except:
            children = game.moves()

        debug_assert(len(children) > 0)

        var best_score = score.Score.MIN

        sort[greater](children)
        if debug:
            print(" moves:", sep="", end="")
            for ref child in children:
                print("", child.move, child.score, end="")

        for ref child in children:
            if debug:
                print("\n#" + "|   " * depth + "> move", child.move, child.score, end="")
            if not score.is_decisive(child.score):
                var child_game = game.copy()
                _ = child_game.play_move(child.move)
                child.score = -self._search(child_game, -b, -a, depth + 1, max_depth)
                if perf_counter_ns() > self._deadline:
                    if debug:
                        print("\n#" + "|   " * depth + "<-- search: timeout", end="")
                    return score.Score(0)

            var child_score = child.score if not score.is_draw(child.score) else 0
            if child_score > best_score:
                best_score = child.score
                if child.score > a:
                    a = child_score

                if depth == 0:
                    self._best_move = child
                    if debug:
                        print("\n#|   set best move", child, end="")

            if debug:
                print("\n#" + "|   " * depth + "< move", child.move, child.score, "| best score", best_score, end="")
            if child_score > b:
                if debug:
                    print("\n#" + "|   " * depth + "cutoff", end="")
                return best_score

        self._moves_cache[game.hash()] = children^
        if debug:
            print("\n#" + "|   " * depth + "<-- search: best score", best_score, end="")
        return best_score
