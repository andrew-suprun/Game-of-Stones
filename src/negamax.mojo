from sys import argv, env_get_bool
from time import perf_counter_ns
from utils.numerics import inf, neg_inf, isinf

from game import TGame, Score, Terminal, MoveScore
from tree import TTree

alias debug = env_get_bool["DEBUG", False]()

struct Negamax[G: TGame, max_moves: Int](TTree):
    alias Game = G
    
    var _no_legal_moves_score: Score
    var _deadline: UInt
    var _moves_cache: Dict[Int, List[MoveScore[G.Move]]]

    fn __init__(out self, no_legal_moves_score: Score):
        self._no_legal_moves_score: Score = no_legal_moves_score
        self._deadline = 0
        self._moves_cache = Dict[Int, List[MoveScore[G.Move]]]()

    fn search(mut self, game: G, duration_ms: Int) -> (Score, List[G.Move]):
        var best_score = neg_inf[DType.float32]()
        var best_pv = List[G.Move]()
        var max_depth = 2
        self._deadline = perf_counter_ns() + 1_000_000 * duration_ms
        self._moves_cache.clear()

        while perf_counter_ns() < self._deadline:
            var (score, pv) = self._search(game, neg_inf[DType.float32](), inf[DType.float32](), 0, max_depth)
            if pv:
                best_score = score
                best_pv = pv
            if debug: print()
            if isinf(score): 
                break
            max_depth += 1
        if debug:
            print("\n#best score", best_score)
        best_pv.reverse()
        return (best_score, best_pv)


    fn _search(mut self, game: G, alpha: Score, beta: Score, depth: Int, max_depth: Int) -> (Score, List[G.Move]):
        @parameter
        fn greater(a: MoveScore[G.Move], b: MoveScore[G.Move]) -> Bool:
            return a.score > b.score

        var a = alpha
        var b = beta
        if depth == max_depth:
            var moves = game.moves(1)
            if not moves:
                return (Score(0), [])
            debug_assert(len(moves) == 1)
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
        debug_assert(len(children) > 0)

        var best_pv = List[G.Move]()
        var best_move = children[0].move
        var best_score = neg_inf[DType.float32]()

        sort[greater](children)
        if debug:
            print(" | moves: ", sep="", end="")
            for ref child in children:
                print(child.move, "", end="")

        for ref child in children:
            if debug: print("\n#" + "|   "*depth + "> move", child.move, child.score, end="")
            if not child.terminal:
                var child_game = game
                child_game.play_move(child.move)
                (score, pv) = self._search(child_game, -b, -a, depth + 1, max_depth)
                child.score = -score
                if perf_counter_ns() > self._deadline:
                    if debug:
                        print("\n#" + "|   "*depth + "<-- search: timeout", end="")
                    return (Score(0), List[G.Move]())
            else:
                pv = List[G.Move]()

            if child.score > best_score:
                best_move = child.move
                best_score = child.score
                best_pv = pv
                if child.score > alpha:
                    a = child.score

            if debug: print("\n#" + "|   "*depth + "< move", child.move, child.score, "b", b, "| best score", best_score,end="")
            if child.score > b:
                if debug: print("\n#" + "|   "*depth + "cutoff", end="")
                return (best_score, List[G.Move]())
        if debug:
            print("\n#" + "|   "*depth + "<-- search: best move", best_move, "score", best_score, end="")
        best_pv.append(best_move)
        self._moves_cache[game.hash()] = children^
        return (best_score, best_pv)

