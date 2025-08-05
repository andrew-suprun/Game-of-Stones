from sys import argv, env_get_bool
from time import perf_counter_ns
from utils.numerics import inf, neg_inf, isinf

from game import TGame, Score, Terminal, MoveScore
from tree import TTree

alias debug = env_get_bool["DEBUG", False]()

struct Negamax[G: TGame, max_moves: Int](TTree):
    alias Game = G
    
    var _no_legal_moves_score: Score
    var _best_score: Score
    var _pv: List[G.Move]
    var _max_depth: Int
    var _deadline: UInt
    var _moves_cache: Dict[Int, List[MoveScore[G.Move]]]

    fn __init__(out self, no_legal_moves_score: Score):
        self._no_legal_moves_score: Score = no_legal_moves_score
        self._best_score = Score(0)
        self._pv = List[G.Move]()
        self._max_depth = 0
        self._deadline = 0
        self._moves_cache = Dict[Int, List[MoveScore[G.Move]]]()

    fn search(mut self, game: G, duration_ms: Int) -> (Score, List[G.Move]):
        self._deadline = perf_counter_ns() + 1_000_000 * duration_ms
        self._moves_cache.clear()

        self._max_depth = 2
        while perf_counter_ns() < self._deadline:
            (score, pv) = self._search(game, neg_inf[DType.float32](), inf[DType.float32](), 0)
            if debug: print()
            if isinf(score): 
                self._best_score = score
                self._pv = pv
                break
            self._max_depth += 1
        return (self._best_score, self._pv)


    fn _search(mut self, game: G, alpha: Score, beta: Score, depth: Int) -> (Score, List[G.Move]):
        @parameter
        fn greater(a: MoveScore[G.Move], b: MoveScore[G.Move]) -> Bool:
            return a.score > b.score

        var a = alpha
        var b = beta
        if depth == self._max_depth:
            var moves = game.moves(1)
            if debug: print("\n#" + "|   "*depth + "leaf: best move", moves[0].move, moves[0].score, end="")
            return (moves[0].score, [moves[0].move])

        if debug: print("\n#" + "|   "*depth + "--> search:", "a:", alpha, "b:", beta, end="")

        var children: List[MoveScore[G.Move]]
        try:
            children = self._moves_cache[game.hash()]
        except:
            children = game.moves(max_moves)
            if not children:
                return (self._no_legal_moves_score, List[G.Move]())

        var best_pv = List[G.Move]()
        var best_move = children[0].move
        var best_score = neg_inf[DType.float32]()

        if debug:
            print(" | moves: ", sep="", end="")
            for ref child in children:
                print(child.move, "", end="")

        for ref child in children:
            if debug: print("\n#" + "|   "*depth + "> move", child.move, child.score, end="")
            if not child.terminal:
                var child_game = game
                child_game.play_move(child.move)
                (score, pv) = self._search(child_game, -b, -a, depth + 1)
                child.score = -score
                if perf_counter_ns() > self._deadline:
                    return (best_score, best_pv)
            else:
                pv = List[G.Move]()

            if child.score > best_score:
                best_move = child.move
                best_score = child.score
                best_pv = pv
                if child.score > alpha:
                    a = child.score

                if depth == 0:
                    self._best_score = child.score
                    pv.append(child.move)
                    pv.reverse()
                    self._pv = pv
                    if debug:
                        print("\n|   set best move", child.move, "score", child.score, end="")
                        print(" pv: ", end="")
                        for move in pv:
                            print(move, "", end="")

            if debug: print("\n#" + "|   "*depth + "< move", child.move, child.score, "b", b, "| best score", best_score,end="")
            if child.score > b:
                if debug: print("\n#" + "|   "*depth + "cutoff", end="")
                return (best_score, List[G.Move]())
        sort[greater](children)
        if debug:
            print("\n#" + "|   "*depth + "<-- search: best move", best_move, "score", best_score, end="")
        best_pv.append(best_move)
        self._moves_cache[game.hash()] = children^
        return (best_score, best_pv)

