from sys import argv, env_get_bool
from time import perf_counter_ns

from score import Score, draw, is_decisive, is_win, loss, is_loss
from game import TGame, MoveScore
from tree import TTree

alias debug = env_get_bool["DEBUG", False]()


struct Negamax[G: TGame, max_moves: Int, no_legal_moves_decision: Score](TTree):
    alias Game = G

    var _best_move: MoveScore[G.Move]
    var _deadline: UInt
    var _moves_cache: Dict[Int, List[MoveScore[G.Move]]]

    fn __init__(out self):
        self._best_move = MoveScore[G.Move](G.Move(), Score(0))
        self._deadline = 0
        self._moves_cache = Dict[Int, List[MoveScore[G.Move]]]()

    fn search(mut self, game: G, duration_ms: Int) -> MoveScore[G.Move]:
        self._deadline = perf_counter_ns() + 1_000_000 * duration_ms
        self._moves_cache.clear()
        var moves = game.moves(1)
        self._best_move = moves[0]
        var max_depth = 1

        while perf_counter_ns() < self._deadline:
            var score = self._search(game, Score.MIN, Score.MAX, 0, max_depth)
            if debug:
                print()
            if is_win(score):
                break
            max_depth += 1
        return self._best_move

    fn _search(mut self, game: G, alpha: Score, beta: Score, depth: Int, max_depth: Int) -> Score:
        @parameter
        fn greater(a: MoveScore[G.Move], b: MoveScore[G.Move]) -> Bool:
            return a.score > b.score

        var a = alpha
        var b = beta
        if depth == max_depth:
            var moves = game.moves(1)
            debug_assert(len(moves) == 1)
            if debug:
                print("\n#" + "|   " * depth + "leaf: best move", moves[0], end="")
            return moves[0].score

        if debug:
            print("\n#" + "|   " * depth + "--> search", end="")

        var children: List[MoveScore[G.Move]]
        try:
            children = self._moves_cache[game.hash()]
        except:
            children = game.moves(max_moves)

        debug_assert(len(children) > 0)

        var best_score = Score.MIN

        sort[greater](children)
        if debug:
            print(" moves:", sep="", end="")
            for ref child in children:
                print("", child.move, child.score, end="")

        for ref child in children:
            if debug:
                print(
                    "\n#" + "|   " * depth + "> move",
                    child.move,
                    child.score,
                    end="",
                )
            if not is_decisive(child.score):
                var child_game = game.copy()
                _ = child_game.play_move(child.move)
                child.score = -self._search(child_game, -b, -a, depth + 1, max_depth)
                if perf_counter_ns() > self._deadline:
                    if debug:
                        print(
                            "\n#" + "|   " * depth + "<-- search: timeout",
                            end="",
                        )
                    return Score(0)

            if child.score > best_score and not is_loss(child.score):
                best_score = child.score
                if child.score > alpha:
                    a = child.score

                if depth == 0:
                    self._best_move = child
                    if debug:
                        print("\n#|   set best move", child, end="")

            if debug:
                print(
                    "\n#" + "|   " * depth + "< move",
                    child.move,
                    child.score,
                    "| best score",
                    best_score,
                    end="",
                )
            if child.score > b:
                if debug:
                    print("\n#" + "|   " * depth + "cutoff", end="")
                return best_score

        self._moves_cache[game.hash()] = children^
        return best_score
