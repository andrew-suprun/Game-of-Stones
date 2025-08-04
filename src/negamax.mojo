from sys import argv, env_get_bool
from utils.numerics import inf, neg_inf

from game import TGame, Score, Terminal

alias debug = env_get_bool["DEBUG", False]()

struct Negamax[Game: TGame, max_moves: Int](Defaultable):
    var best_move: Game.Move
    var _max_depth: Int
    var _moves_cache: Dict[Int, List[(Game.Move, Score, Terminal)]]

    fn __init__(out self):
        self.best_move = Game.Move()
        self._max_depth = 0
        self._moves_cache = Dict[Int, List[(Game.Move, Score, Terminal)]]()

    fn expand(mut self, game: Game, max_depth: Int) -> (Score, List[Game.Move]):
        self._max_depth = max_depth
        self._moves_cache.clear()

        var result = (Score(0), List[Game.Move]())
        for depth in range(2, max_depth + 1):
            self._max_depth = depth
            result = self._expand(game, neg_inf[DType.float32](), inf[DType.float32](), 0)
            if debug: print()
        return result


    fn _expand(mut self, game: Game, alpha: Score, beta: Score, depth: Int) -> (Score, List[Game.Move]):
        @parameter
        fn greater(a: (Game.Move, Score, Terminal), b: (Game.Move, Score, Terminal)) -> Bool:
            return a[1] > b[1]

        var a = alpha
        var b = beta
        if depth == self._max_depth:
            var moves = game.moves(1)
            if debug: print("\n" + "|   "*depth + "leaf: best move", moves[0][0], moves[0][1], end="")
            return (moves[0][1], [moves[0][0]])

        if debug: print("\n" + "|   "*depth + "--> expand:", "a:", alpha, "b:", beta, end="")
        var best_score = neg_inf[DType.float32]()
        var best_pv = List[Game.Move]()
        var best_move = Game.Move()
        var moves: List[(Game.Move, Score, Terminal)]

        try:
            moves = self._moves_cache[game.hash()]
        except:
            moves = game.moves(max_moves)

        if debug:
            print(" | moves: ", sep="", end="")
            for ref (child_move, _, _) in moves:
                print(child_move, "", end="")

        for ref move in moves:
            if debug: print("\n" + "|   "*depth + "> move", move[0], move[1], end="")
            if not move[2]:
                var child_game = game
                child_game.play_move(move[0])
                (score, pv) = self._expand(child_game, -b, -a, depth + 1)
                move[1] = -score
            else:
                pv = List[Game.Move]()

            if move[1] > best_score:
                if depth == 0:
                    self.best_move = move[0]
                    if debug:
                        print("\n|   set best move", move[0], "score", move[1], end="")
                        print(" pv: ", end="")
                        for move in pv[::-1]:
                            print(move, "", end="")

                best_score = move[1]
                best_pv = pv
                best_move = move[0]
                if move[1] > alpha:
                    a = move[1]
            if debug: print("\n" + "|   "*depth + "< move", move[0], move[1], "| best score", best_score,end="")
            if move[1] > b:
                if debug: print("\n" + "|   "*depth + "cutoff", end="")
                return (best_score, List[Game.Move]())
        sort[greater](moves)
        if debug:
            for i in range(len(moves)):
                if best_move == moves[i][0]:
                    print("\n" + "|   "*depth + "<-- expand: best move", best_move, i, "score", best_score, end="")
        best_pv.append(best_move)
        self._moves_cache[game.hash()] = moves^
        return (best_score, best_pv)

