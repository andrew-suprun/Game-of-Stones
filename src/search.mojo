from logger import Logger
from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore


fn search[Tree: Negamax](mut game: Tree.Game, duration_ms: Int) -> MoveScore[Tree.Game.Move]:
    var tree = Tree()
    var best_move = MoveScore[Tree.Game.Move](Tree.Game.Move(), Score.no_score())
    var depth = 1
    var deadline = perf_counter_ns() + 1_000_000 * duration_ms
    while perf_counter_ns() < deadline:
        var move = tree.search(game, depth, deadline)
        if not move.score.is_set():
            break
        best_move = move
    return best_move


trait Negamax(Defaultable):
    alias Game: TGame

    fn search(mut self, mut game: Self.Game, max_depth: Int, deadline: UInt) -> MoveScore[Self.Game.Move]:
        ...

@fieldwise_init
struct BasicNegamax[G: TGame](Negamax):
    alias Game = G

    fn search(mut self, mut game: Self.Game, max_depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        var score = self._search(game, Score.loss(), Score.win(), max_depth, deadline)
        return MoveScore(G.Move(), score)

    fn _search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, deadline: UInt) -> Score:
        var score = Score.loss()
        var moves = game.moves()
        debug_assert(len(moves) > 0)
        for move in moves:
            var new_score = move.score
            if depth > 0 and not new_score.is_decisive():
                _ = game.play_move(move.move)
                new_score = -self._search(game, -beta, -alpha, depth - 1, deadline)
                game.undo_move(move.move)
            if not new_score.is_set() or perf_counter_ns() > deadline:
                return Score.no_score()
            score = max(score, new_score)

        return score

@fieldwise_init
struct AlphaBetaNegamax[G: TGame](Negamax):
    alias Game = G

    var best_move: G.Move
    var logger: Logger

    fn __init__(out self):
        self.best_move = G.Move()
        self.logger = Logger(prefix = "ab: ")

    fn search(mut self, mut game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        var score = self._search(game, Score.loss(), Score.win(), 0, depth, deadline)
        return MoveScore[G.Move](self.best_move, score)

    fn _search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        self.logger.debug("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")
        var score = Score.loss()
        var moves = game.moves()
        if depth == max_depth:
            for move in moves:
                score = max(score, move.score)
            self.logger.debug("|  " * depth, depth, " << search: max-depth score: ", score, sep="")
            return score

        var start = perf_counter_ns()
        sort[Self.greater](moves)
        for move in moves:
            self.logger.debug("|  " * depth, depth, " > move: ", move.move, sep="")
            var new_score = move.score
            if not new_score.is_decisive():
                _ = game.play_move(move.move)
                new_score = -self._search(game, -beta, -alpha, depth + 1, max_depth, deadline)
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

    @staticmethod
    @parameter
    fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score


@fieldwise_init
struct PrincipalVariationNegamax[G: TGame](Negamax):
    alias Game = G

    var best_move: G.Move
    var logger: Logger

    fn __init__(out self):
        self.best_move = G.Move()
        self.logger = Logger(prefix = "pv: ")

    fn search(mut self, mut game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        var score = self._search(game, Score.loss(), Score.win(), 0, depth, deadline)
        return MoveScore[G.Move](self.best_move, score)

    fn _search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        @parameter
        fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
            return a.score > b.score

        debug_assert(depth >= 1)
        self.logger.debug("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")
        var best_score = Score.loss()
        var moves = game.moves()
        if depth == max_depth:
            for move in moves:
                best_score = max(best_score, move.score)
            self.logger.debug("|  " * depth, depth, " << search: max-depth score: ", best_score, sep="")
            return best_score

        var first_move = True
        var start = perf_counter_ns()
        sort[greater](moves)
        for move in moves:
            if move.score.is_decisive():
                self.logger.debug("|  " * depth, depth, " <> decisive move: ", move, sep="")
                if move.score.is_win():
                    self.logger.debug("|  " * depth, depth, " < cut-winning-move [", alpha, ":", beta, "]", sep="")
                    return move.score
                best_score = max(best_score, move.score)
                alpha = max(alpha, move.score)
                continue

            self.logger.debug("|  " * depth, depth, " > move: ", move.move, sep="")

            # first move
            if first_move:
                _ = game.play_move(move.move)
                var score = -self._search(game, -beta, -alpha, depth + 1, max_depth, deadline)
                game.undo_move(move.move)
                best_score = max(best_score, score)
                if score > beta or score.is_win():
                    self.logger.debug("|  " * depth, depth, " < cut-first-move [", alpha, ":", beta, "]", sep="")
                    return score

                self.logger.debug("|  " * depth, depth, " < first-move-score: ", score, " alpha: ", alpha, sep="")
                if score < alpha:
                    continue
                else:
                    first_move = False
                    alpha = score
                continue


            # zero window
            _ = game.play_move(move.move)
            var score = -self._search(game, -alpha, -alpha, depth + 1, max_depth, deadline)
            best_score = max(best_score, score)
            if score > beta or score.is_win():
                game.undo_move(move.move)
                self.logger.debug("|  " * depth, depth, " < cut-zero-window [", alpha, ":", beta, "]", sep="")
                return score
            if not score > alpha or depth + 1 == max_depth:
                game.undo_move(move.move)
                self.logger.debug("|  " * depth, depth, " < zero-window-score: ", score, " alpha: ", alpha, sep="")
                continue
            else:
                alpha = score

            # full window
            score = -self._search(game, -beta, -alpha, depth + 1, max_depth, deadline)
            game.undo_move(move.move)
            best_score = max(best_score, score)
            alpha = max(alpha, score)
            if score > beta or score.is_win():
                self.logger.debug("|  " * depth, depth, " < cut-full-window [", alpha, ":", beta, "]", sep="")
                return score

            self.logger.debug("|  " * depth, depth, " < full-window-score: ", score, " alpha: ", alpha, sep="")

        self.logger.debug("|  " * depth, depth, " << search: score: ", best_score, " ns: ", perf_counter_ns() - start, sep="")
        return best_score


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

    # game = Game()
    # _ = game.play_move("j10")
    # _ = game.play_move("j9-i10")
    # print("Alpha-Beta Negamax")
    # move = search[AlphaBetaNegamax[Game]](game, timeout)
    # print("move", move)
    # print()

    # game = Game()
    # _ = game.play_move("j10")
    # _ = game.play_move("j9-i10")
    # print("Principal Variation Negamax")
    # move = search[PrincipalVariationNegamax[Game]](game, timeout)
    # print("move", move)
    # print()


    # print("Basic Negamax")
    # for depth in range(1, 5):
    #     game = Game()
    #     _ = game.play_move("j10")
    #     _ = game.play_move("j9-i10")

    #     var tree = BasicNegamax[Game]()
    #     var start = perf_counter_ns()
    #     var move = tree.search(game, depth, perf_counter_ns() + 20_000_000_000)
    #     print("depth", depth, "score", move.score, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    print("Alpha-Beta Negamax")
    for depth in range(3, 4):
        game = Game()
        _ = game.play_move("j10")
        _ = game.play_move("j9-i10")

        var tree = AlphaBetaNegamax[Game]()
        var start = perf_counter_ns()
        var move = tree.search(game, depth, perf_counter_ns() + 20_000_000_000)
        print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    print()

    print("Principal Variation Negamax")
    for depth in range(3, 4):
        game = Game()
        _ = game.play_move("j10")
        _ = game.play_move("j9-i10")

        var tree = PrincipalVariationNegamax[Game]()
        var start = perf_counter_ns()
        var move = tree.search(game, depth, perf_counter_ns() + 20_000_000_000)
        print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)
