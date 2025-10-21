from logger import Logger
from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore


fn search[Tree: Negamax](mut game: Tree.Game, duration_ms: UInt) -> MoveScore[Tree.Game.Move]:
    var logger = Logger(prefix="s:  ")
    var tree = Tree()
    var best_move = MoveScore[Tree.Game.Move](Tree.Game.Move(), Score.no_score())
    var depth = 1
    var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
    while perf_counter_ns() < deadline:
        start = perf_counter_ns()
        var move = tree.search(game, depth, deadline)
        if not move.score.is_set():
            break
        logger.info("depth", depth, "move", move, "time", (perf_counter_ns() - start) / 1_000_000_000)
        best_move = move
        depth += 1
    return best_move


trait Negamax(Defaultable):
    alias Game: TGame

    fn search(mut self, mut game: Self.Game, max_depth: Int, deadline: UInt) -> MoveScore[Self.Game.Move]:
        ...


struct BasicNegamax[G: TGame](Negamax):
    alias Game = G

    var best_move: G.Move

    fn __init__(out self):
        self.best_move = G.Move()

    fn search(mut self, mut game: Self.Game, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        var score = self._search(game, Score.loss(), Score.win(), 0, depth, deadline)
        return MoveScore(self.best_move, score)

    fn _search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        if perf_counter_ns() > deadline:
            return Score.no_score()

        var best_score = Score.loss()
        var moves = game.moves()
        debug_assert(len(moves) > 0)
        for ref move in moves:
            if depth < max_depth and not move.score.is_decisive():
                _ = game.play_move(move.move)
                move.score = -self._search(game, -beta, -alpha, depth + 1, max_depth, deadline)
                game.undo_move(move.move)
            if not move.score.is_set():
                return Score.no_score()
            
            if move.score > best_score:
                best_score = move.score
                if depth == 0:
                    self.best_move = move.move

        return best_score


struct AlphaBetaNegamax[G: TGame](Negamax):
    alias Game = G

    var best_move: G.Move
    var logger: Logger

    fn __init__(out self):
        self.best_move = G.Move()
        self.logger = Logger(prefix="ab: ")

    fn search(mut self, mut game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        var score = self._search(game, Score.loss(), Score.win(), 0, depth, deadline)
        return MoveScore[G.Move](self.best_move, score)

    fn _search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        if perf_counter_ns() > deadline:
            return Score.no_score()

        var best_score = Score.loss()
        var moves = game.moves()
        if depth == max_depth:
            for move in moves:
                best_score = max(best_score, move.score)
            return best_score

        sort[Self.greater](moves)
        self.logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")
        for ref move in moves:
            if not move.score.is_decisive():
                self.logger.trace("|  " * depth, depth, " > move: ", move.move, " [", alpha, ":", beta, "]", sep="")
                _ = game.play_move(move.move)
                move.score = -self._search(game, -beta, -alpha, depth + 1, max_depth, deadline)
                game.undo_move(move.move)
                self.logger.trace("|  " * depth, depth, " < move: ", move, " [", alpha, ":", beta, "]", sep="")
            if not move.score.is_set():
                return Score.no_score()

            if move.score > best_score:
                best_score = move.score
                if depth == 0:
                    self.best_move = move.move
                    self.logger.debug("depth", max_depth, "move", move)

            if best_score > beta:
                break
            
            alpha = max(alpha, move.score)

        self.logger.trace("|  " * depth, depth, " << search: score: ", best_score, sep="")
        return best_score

    @staticmethod
    @parameter
    fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score


struct PrincipalVariationNegamax[G: TGame](Negamax):
    alias Game = G

    var best_move: G.Move
    var logger: Logger

    fn __init__(out self):
        self.best_move = G.Move()
        self.logger = Logger(prefix="pv: ")

    fn search(mut self, mut game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        var score = self._search(game, Score.loss(), Score.win(), 0, depth, deadline)
        return MoveScore[G.Move](self.best_move, score)

    fn _search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        if perf_counter_ns() > deadline:
            return Score.no_score()

        var best_score = Score.loss()
        var moves = game.moves()
        if depth == max_depth:
            for move in moves:
                best_score = max(best_score, move.score)
            return best_score

        var first_move = True
        sort[Self.greater](moves)
        self.logger.debug("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")
        for ref move in moves:
            if move.score.is_decisive():
                self.logger.trace("|  " * depth, depth, " <> decisive move: ", move, sep="")
                if move.score.is_win():
                    self.logger.trace("|  " * depth, depth, " < move: ", move.move, " cut-winning-move [", alpha, ":", beta, "]", sep="")
                    return move.score
                if move.score > best_score:
                    best_score = move.score
                    if depth == 0:
                        self.best_move = move.move
                alpha = max(alpha, move.score)
                continue


            # first move
            if first_move:
                self.logger.trace("|  " * depth, depth, " > first-move: ", move.move, " [", alpha, ":", beta, "]", sep="")
                _ = game.play_move(move.move)
                move.score = -self._search(game, -beta, -alpha, depth + 1, max_depth, deadline)
                game.undo_move(move.move)
                self.logger.trace("|  " * depth, depth, " < first-move: ", move, " [", alpha, ":", beta, "] ns: ", sep="")
                if not move.score.is_set():
                    return Score.no_score()
                if move.score > best_score:
                    best_score = move.score
                    if depth == 0:
                        self.best_move = move.move
                if move.score > beta or move.score.is_win():
                    self.logger.debug("|  " * depth, depth, " << search: cut-first-move-score: ", best_score, sep="")
                    return move.score

                if move.score < alpha:
                    continue
                else:
                    first_move = False
                    alpha = move.score
                continue

            # zero window
            self.logger.trace("|  " * depth, depth, " > zero-window-move: ", move.move, " [", alpha, ":", alpha, "]", sep="")
            _ = game.play_move(move.move)
            move.score = -self._search(game, -alpha, -alpha, depth + 1, max_depth, deadline)
            self.logger.trace("|  " * depth, depth, " < zero-window-move: ", move, " [", alpha, ":", alpha, "] ns: ", sep="")
            if not move.score.is_set():
                game.undo_move(move.move)
                return Score.no_score()
            if move.score > best_score:
                best_score = move.score
                if depth == 0:
                    self.best_move = move.move
            if move.score > beta or move.score.is_win():
                game.undo_move(move.move)
                self.logger.debug("|  " * depth, depth, " << search: cut-zero-window-score: ", best_score, sep="")
                return move.score
            if move.score <= alpha or depth + 1 == max_depth:
                game.undo_move(move.move)
                continue
            alpha = max(alpha, move.score)

            # full window
            self.logger.trace("|  " * depth, depth, " > full-window-move: ", move.move, " [", alpha, ":", beta, "]", sep="")
            move.score = -self._search(game, -beta, -alpha, depth + 1, max_depth, deadline)
            game.undo_move(move.move)
            self.logger.trace("|  " * depth, depth, " < full-window-move: ", move, " [", alpha, ":", beta, "] ns: ", sep="")
            if not move.score.is_set():
                return Score.no_score()
            if move.score > best_score:
                best_score = move.score
                if depth == 0:
                    self.best_move = move.move
            if move.score > beta or move.score.is_win():
                self.logger.debug("|  " * depth, depth, " << search: cut-full-window-score: ", best_score, sep="")
                return move.score

            alpha = max(alpha, move.score)

        self.logger.debug("|  " * depth, depth, " << search: score: ", best_score, sep="")
        return best_score

    @staticmethod
    @parameter
    fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score


from connect6 import Connect6

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
alias timeout = 15_000


fn main() raises:
    game = Game()
    _ = game.play_move("j10")
    _ = game.play_move("j9-i10")
    print("Basic Negamax")
    var move = search[BasicNegamax[Game]](game, timeout)
    print("move", move)
    print()

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
    #     var move = tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    #     print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    # print("Alpha-Beta Negamax")
    # for depth in range(1, 8):
    #     game = Game()
    #     _ = game.play_move("j10")
    #     _ = game.play_move("j9-i10")

    #     var tree = AlphaBetaNegamax[Game]()
    #     var start = perf_counter_ns()
    #     var move = tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    #     print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    # print("Principal Variation Negamax")
    # for depth in range(1, 8):
    #     game = Game()
    #     _ = game.play_move("j10")
    #     _ = game.play_move("j9-i10")

    #     var tree = PrincipalVariationNegamax[Game]()
    #     var start = perf_counter_ns()
    #     var move = tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    #     print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)
