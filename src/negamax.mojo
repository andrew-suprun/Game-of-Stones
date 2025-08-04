from sys import argv, env_get_bool
from utils.numerics import inf, neg_inf

from game import TGame, Score, Terminal, MoveScore

alias debug = env_get_bool["DEBUG", False]()

struct Negamax[Game: TGame, max_moves: Int](Defaultable):
    var best_move: Game.Move
    var _max_depth: Int
    var _moves_cache: Dict[Int, List[MoveScore[Game.Move]]]

    fn __init__(out self):
        self.best_move = Game.Move()
        self._max_depth = 0
        self._moves_cache = Dict[Int, List[MoveScore[Game.Move]]]()

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
        fn greater(a: MoveScore[Game.Move], b: MoveScore[Game.Move]) -> Bool:
            return a.score > b.score

        var a = alpha
        var b = beta
        if depth == self._max_depth:
            var moves = game.moves(1)
            if debug: print("\n" + "|   "*depth + "leaf: best move", moves[0].move, moves[0].score, end="")
            return (moves[0].score, [moves[0].move])

        if debug: print("\n" + "|   "*depth + "--> expand:", "a:", alpha, "b:", beta, end="")
        var best_score = neg_inf[DType.float32]()
        var best_pv = List[Game.Move]()
        var best_move = Game.Move()

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
                (score, pv) = self._expand(child_game, -b, -a, depth + 1)
                child.score = -score
            else:
                pv = List[Game.Move]()

            if child.score > best_score:
                if depth == 0:
                    self.best_move = child.move
                    if debug:
                        print("\n|   set best move", child.move, "score", child.score, end="")
                        print(" pv: ", end="")
                        for move in pv[::-1]:
                            print(move, "", end="")

                best_score = child.score
                best_pv = pv
                best_move = child.move
                if child.score > alpha:
                    a = child.score
            if debug: print("\n" + "|   "*depth + "< move", child.move, child.score, "| best score", best_score,end="")
            if child.score > b:
                if debug: print("\n" + "|   "*depth + "cutoff", end="")
                return (best_score, List[Game.Move]())
        sort[greater](children)
        if debug:
            for i in range(len(children)):
                if best_move == children[i].move:
                    print("\n" + "|   "*depth + "<-- expand: best move", best_move, i, "score", best_score, end="")
        best_pv.append(best_move)
        self._moves_cache[game.hash()] = children^
        return (best_score, best_pv)

