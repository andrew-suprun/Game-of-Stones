from logger import Logger
from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore


fn search[Tree: Negamax](mut game: Tree.Game, duration_ms: Int) -> MoveScore[Tree.Game.Move]:
    @parameter
    fn greater(a: MoveScore[Tree.Game.Move], b: MoveScore[Tree.Game.Move]) -> Bool:
        return a.score > b.score

    var logger = Logger(prefix = "s:  ")
    var deadline = perf_counter_ns() + 1_000_000 * duration_ms


    logger.info("> ID search")


    var tree = Tree()
    var roots = game.moves()
    sort[greater](roots)
    debug_assert(len(roots) > 0)
    if len(roots) == 1 or roots[0].score.is_decisive():
        logger.info("< decisive:", roots[0])
        return roots[0]

    var best_move = roots[0]
    var max_depth = 0
    while True:
        logger.debug("> depth:", max_depth + 1)
        var first_move = True
        var alpha = Score.loss()
        var start = perf_counter_ns()
        for ref root in roots:
            logger.debug("> move:", root.move)
            root.score = game.play_move(root.move)
            if root.score.is_set() and not root.score.is_decisive():
                root.score = -tree.search(game, Score.loss(), -alpha, max_depth, deadline)
                alpha = max(alpha, root.score)
                game.undo_move(root.move)

            logger.debug("< root:", root)

            if not root.score.is_set():
                logger.info("< best move:", best_move, "depth", max_depth + 1)
                tree.stats()
                return best_move

            if first_move or root.score > best_move.score:
                first_move = False
                best_move = root

        logger.info("< depth", max_depth + 1, "move", best_move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

        max_depth += 1
        sort[greater](roots)
        if roots[0].score.is_decisive():
            logger.info("< decisive-2:", roots[0])
            return roots[0]


trait Negamax(Defaultable):
    alias Game: TGame

    fn search(mut self, mut game: Self.Game, var alpha: Score, beta: Score, max_depth: Int, deadline: UInt) -> Score:
        ...

    fn stats(self):
        ...

@fieldwise_init
struct BasicNegamax[G: TGame](Negamax):
    alias Game = G


    fn search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, deadline: UInt) -> Score:
        var score = Score.loss()
        var moves = game.moves()
        for move in moves:
            var new_score = move.score
            if depth > 0 and not new_score.is_decisive():
                _ = game.play_move(move.move)
                new_score = -self.search(game, -beta, -alpha, depth - 1, deadline)
                game.undo_move(move.move)
            if not new_score.is_set() or perf_counter_ns() > deadline:
                return Score.no_score()
            score = max(score, new_score)

        return score

    fn stats(self):
        ...

@fieldwise_init
struct AlphaBetaNegamax[G: TGame](Negamax):
    alias Game = G

    var full: Int
    var logger: Logger

    fn __init__(out self):
        self.full = 0
        self.logger = Logger(prefix = "ab: ")

    fn search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, deadline: UInt) -> Score:
        return self.search(game, alpha, beta, 0, depth, deadline)

    fn search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        @parameter
        fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
            return a.score > b.score

        self.logger.debug("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")
        var score = Score.loss()
        var moves = game.moves()
        if depth == max_depth:
            for move in moves:
                score = max(score, move.score)
            self.logger.debug("|  " * depth, depth, " << search: max-depth score: ", score, sep="")
            return score

        var start = perf_counter_ns()
        sort[greater](moves)
        for move in moves:
            self.logger.debug("|  " * depth, depth, " > move: ", move.move, sep="")
            var new_score = move.score
            if not new_score.is_decisive():
                _ = game.play_move(move.move)
                new_score = -self.search(game, -beta, -alpha, depth + 1, max_depth, deadline)
                self.full += 1
                game.undo_move(move.move)
            if not new_score.is_set() or perf_counter_ns() > deadline:
                self.logger.debug("|  " * depth, depth, " < no-score move: ", move.move, sep="")
                return Score.no_score()
            score = max(score, new_score)
            alpha = max(alpha, new_score)
            if alpha > beta:
                self.logger.debug("|  " * depth, depth, " < cut [", alpha, ":", beta, "]", sep="")
                break

            self.logger.debug("|  " * depth, depth, " < move: ", move.move, " alpha: ", alpha, sep="")

        self.logger.debug("|  " * depth, depth, " << search: score: ", score, " ns: ", perf_counter_ns() - start, sep="")
        return score

    fn stats(self):
        print("full", self.full)

@fieldwise_init
struct PrincipalVariationNegamax[G: TGame](Negamax):
    alias Game = G

    var full: Int
    var zero: Int
    var logger: Logger

    fn __init__(out self):
        self.full = 0
        self.zero = 0
        self.logger = Logger(prefix = "pv: ")

    fn search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, deadline: UInt) -> Score:
        return self.search(game, alpha, beta, 0, depth, deadline)

    fn search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        @parameter
        fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
            return a.score > b.score

        self.logger.debug("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")
        var score = Score.loss()
        var moves = game.moves()
        var full_window = True
        var zero_window = False
        if depth == max_depth:
            for move in moves:
                score = max(score, move.score)
            self.logger.debug("|  " * depth, depth, " << search: max-depth score: ", score, sep="")
            return score

        var start = perf_counter_ns()
        sort[greater](moves)
        for move in moves:
            self.logger.debug("|  " * depth, depth, " > move: ", move.move, sep="")
            var new_score = move.score
            if new_score.is_decisive():
                score = max(score, new_score)
                alpha = max(alpha, new_score)
                if alpha > beta:
                    self.logger.debug("|  " * depth, depth, " < cut-1 [", alpha, ":", beta, "]", sep="")
                    break
                self.logger.debug("|  " * depth, depth, " < decisive move: ", move.move, sep="")
                continue

            _ = game.play_move(move.move)

            if zero_window:
                self.zero += 1
                new_score = -self.search(game, -alpha, -alpha, depth + 1, max_depth, deadline)
                if not new_score.is_set() or perf_counter_ns() > deadline:
                    game.undo_move(move.move)
                    self.logger.debug("|  " * depth, depth, " < no-score-1 move: ", move.move, sep="")
                    return Score.no_score()
                full_window = new_score > alpha

            if full_window:
                self.full += 1
                new_score = -self.search(game, -beta, -alpha, depth + 1, max_depth, deadline)
                if not new_score.is_set() or perf_counter_ns() > deadline:
                    game.undo_move(move.move)
                    self.logger.debug("|  " * depth, depth, " < no-score-2 move: ", move.move, sep="")
                    return Score.no_score()
                score = max(score, new_score)
                alpha = max(alpha, new_score)
                if alpha > beta:
                    game.undo_move(move.move)
                    self.logger.debug("|  " * depth, depth, " < cut-2 [", alpha, ":", beta, "]", sep="")
                    break
                zero_window = True
                full_window = False
            
            self.logger.debug("|  " * depth, depth, " < move: ", move.move, " alpha: ", alpha, sep="")

            game.undo_move(move.move)

        self.logger.debug("|  " * depth, depth, " << search: score: ", score, " ns: ", perf_counter_ns() - start, sep="")
        return score

    fn stats(self):
        print("zero", self.zero, "full", self.full)


from connect6 import Connect6
alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]


# fn run[Tree: Negamax](title: StaticString) raises:
#     game = Game()
#     _ = game.play_move("j10")
#     _ = game.play_move("j9-i10")
#     print(title, "Negamax")
#     move = search[Tree](game, 20_000)
#     print("move", move)
#     print()

alias timeout = 200

fn main() raises:
    # run[BasicNegamax[Game]]("Basic")

    # var game = Game()
    # _ = game.play_move("j10")
    # _ = game.play_move("j9-i10")
    # print("Basic Negamax")
    # var move = search[BasicNegamax[Game]](game, timeout)
    # print("move", move)
    # print()

    game = Game()
    _ = game.play_move("j10")
    _ = game.play_move("j9-i10")
    print("Alpha-Beta Negamax")
    move = search[AlphaBetaNegamax[Game]](game, timeout)
    print("move", move)
    print()

    game = Game()
    _ = game.play_move("j10")
    _ = game.play_move("j9-i10")
    print("Principal Variation Negamax")
    move = search[PrincipalVariationNegamax[Game]](game, timeout)
    print("move", move)
    print()


    # print("Basic Negamax")
    # for depth in range(1, 5):
    #     game = Game()
    #     _ = game.play_move("j10")
    #     _ = game.play_move("j9-i10")

    #     var tree = BasicNegamax[Game]()
    #     var start = perf_counter_ns()
    #     var score = tree.search(game, Score.loss(), Score.win(), depth, perf_counter_ns() + 20_000_000_000)
    #     print("depth", depth, "score", score, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    # print("Alpha-Beta Negamax")
    # for depth in range(1, 5):
    #     game = Game()
    #     _ = game.play_move("j10")
    #     _ = game.play_move("j9-i10")

    #     var tree = AlphaBetaNegamax[Game]()
    #     var start = perf_counter_ns()
    #     var score = tree.search(game, Score.loss(), Score.win(), depth, perf_counter_ns() + 20_000_000_000)
    #     print("depth", depth, "score", score, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    # for alpha in [-100, 0, 5, 6, 7, 10, 100]:
    #     game = Game()
    #     _ = game.play_move("j10")
    #     _ = game.play_move("j9-i10")

    #     var tree = PrincipalVariationNegamax[Game]()
    #     var start = perf_counter_ns()
    #     var score = tree.search(game, Score.loss(), Score.win(), 2, perf_counter_ns() + 20_000_000_000)
    #     print("alpha", alpha, "score", score, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)
