from sys import argv, env_get_bool
from time import perf_counter_ns
from utils.numerics import inf, neg_inf

from game import TGame, Score, Terminal, MoveScore

alias debug = env_get_bool["DEBUG", False]()

struct Negamax[Game: TGame, max_moves: Int](Defaultable):
    var _best_score: Score
    var _pv: List[Game.Move]
    var _max_depth: Int
    var _deadline: UInt
    var _moves_cache: Dict[Int, List[MoveScore[Game.Move]]]

    fn __init__(out self):
        self._best_score = Score(0)
        self._pv = List[Game.Move]()
        self._max_depth = 0
        self._deadline = 0
        self._moves_cache = Dict[Int, List[MoveScore[Game.Move]]]()

    fn search(mut self, game: Game, duration_ms: Int) -> (Score, List[Game.Move]):
        self._deadline = perf_counter_ns() + 1_000_000 * duration_ms
        self._moves_cache.clear()

        self._max_depth = 2
        while perf_counter_ns() < self._deadline:
            _ = self._search(game, neg_inf[DType.float32](), inf[DType.float32](), 0)
            if debug: print()
            self._max_depth += 1
        return (self._best_score, self._pv)


    fn _search(mut self, game: Game, alpha: Score, beta: Score, depth: Int) -> (Score, List[Game.Move]):
        @parameter
        fn greater(a: MoveScore[Game.Move], b: MoveScore[Game.Move]) -> Bool:
            return a.score > b.score

        var best_score = neg_inf[DType.float32]()
        var best_pv = List[Game.Move]()
        var best_move = Game.Move()

        var a = alpha
        var b = beta
        if depth == self._max_depth:
            var moves = game.moves(1)
            if debug: print("\n" + "|   "*depth + "leaf: best move", moves[0].move, moves[0].score, end="")
            return (moves[0].score, [moves[0].move])

        if debug: print("\n" + "|   "*depth + "--> search:", "a:", alpha, "b:", beta, end="")

        var children: List[MoveScore[Game.Move]]
        try:
            children = self._moves_cache[game.hash()]
        except:
            children = game.moves(max_moves)

        if debug:
            print(" | moves: ", sep="", end="")
            for ref child in children:
                print(child.move, "", end="")

        for ref child in children:
            if debug: print("\n" + "|   "*depth + "> move", child.move, child.score, end="")
            if not child.terminal:
                var child_game = game
                child_game.play_move(child.move)
                (score, pv) = self._search(child_game, -b, -a, depth + 1)
                child.score = -score
                if perf_counter_ns() > self._deadline:
                    return (best_score, best_pv)
            else:
                pv = List[Game.Move]()

            if child.score > best_score:
                best_move = child.move
                best_score = child.score
                best_pv = pv
                if child.score > alpha:
                    a = child.score

                if depth == 0:
                    pv.append(child.move)
                    pv.reverse()
                    self._best_score = child.score
                    self._pv = pv
                    if debug:
                        print("\n|   set best move", child.move, "score", child.score, end="")
                        print(" pv: ", end="")
                        for move in pv:
                            print(move, "", end="")

            if debug: print("\n" + "|   "*depth + "< move", child.move, child.score, "| best score", best_score,end="")
            if child.score > b:
                if debug: print("\n" + "|   "*depth + "cutoff", end="")
                return (best_score, List[Game.Move]())
        sort[greater](children)
        if debug:
            for i in range(len(children)):
                if best_move == children[i].move:
                    print("\n" + "|   "*depth + "<-- search: best move", best_move, i, "score", best_score, end="")
        best_pv.append(best_move)
        self._moves_cache[game.hash()] = children^
        return (best_score, best_pv)

