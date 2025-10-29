from logger import Logger
from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore


alias trace_level = env_get_int["TRACE_LEVEL", 8]()


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
        logger.info("#", Tree.name(), "depth", depth, "move", move, "time", (perf_counter_ns() - start) / 1_000_000_000)
        best_move = move
        depth += 1
    return best_move


trait Negamax(Defaultable):
    alias Game: TGame

    @staticmethod
    fn name() -> StaticString:
        ...

    fn search(mut self, mut game: Self.Game, max_depth: Int, deadline: UInt) -> MoveScore[Self.Game.Move]:
        ...
    

struct BasicNegamax[G: TGame](Negamax):
    alias Game = G

    var best_move: G.Move

    @staticmethod
    fn name() -> StaticString:
        return "Basic Negamax"

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
        for ref move in moves:
            if depth < max_depth and not move.score.is_decisive():
                _ = game.play_move(move.move)
                move.score = -self._search(game, Score.loss(), Score.win(), depth + 1, max_depth, deadline)
                game.undo_move(move.move)
            if not move.score.is_set():
                return Score.no_score()
            
            if move.score > best_score:
                best_score = move.score
                if depth == 0:
                    self.best_move = move.move
            
        return best_score

    @staticmethod
    @parameter
    fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score


struct AlphaBetaNegamax[G: TGame](Negamax):
    alias Game = G

    var best_move: MoveScore[G.Move]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Alpha-Beta Negamax"

    fn __init__(out self):
        self.best_move = MoveScore[G.Move](G.Move(), Score.no_score())
        self.logger = Logger(prefix="ab: ")

    fn search(mut self, mut game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        _ = self._search(game, Score.loss(), Score.win(), 0, depth, deadline)
        return self.best_move

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
        
        if depth <= trace_level:
            self.logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        for ref move in moves:
            if depth <= trace_level:
                self.logger.trace("|  " * depth, depth, " > move: ", move.move, " [", alpha, ":", beta, "]", sep="")
            if not move.score.is_decisive():
                _ = game.play_move(move.move)
                move.score = -self._search(game, -beta, -alpha, depth + 1, max_depth, deadline)
                game.undo_move(move.move)
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " < move: ", move.move, " [", alpha, ":", beta, "]", " score: ", move.score, sep="")
            else:
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " < decisive move: ", move.move, " [", alpha, ":", beta, "]", " score: ", move.score, sep="")

            if not move.score.is_set():
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " << search: timeout", sep="")
                return Score.no_score()

            if move.score > best_score:
                best_score = move.score
                if depth == 0:
                    self.best_move = move
                    self.logger.debug("best move", self.best_move)

            if best_score > beta:
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                return best_score
            
            alpha = max(alpha, move.score)

        if depth <= trace_level:
            self.logger.trace("|  " * depth, depth, " << search: score: ", best_score, sep="")
        return best_score

    @staticmethod
    @parameter
    fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score


struct AlphaBetaNegamaxWithMemory[G: TGame](Negamax):
    alias Game = G

    var root: AlphaBetaNode[G]
    var best_move: MoveScore[G.Move]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Alpha-Beta Negamax With Memory"

    fn __init__(out self):
        self.root = AlphaBetaNode[G](G.Move(), Score.no_score())
        self.best_move = MoveScore[G.Move](G.Move(), Score.no_score())
        self.logger = Logger(prefix="ab+: ")

    fn search(mut self, mut game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        _ = self.root._search(game, Score.loss(), Score.win(), 0, depth, deadline, self.best_move, self.logger)
        return self.best_move


struct AlphaBetaNode[G: TGame](Copyable, Movable, Writable):
    var move: G.Move
    var score: Score
    var children: List[Self]

    fn __init__(out self, move: G.Move, score: Score):
        self.move = move
        self.score = score
        self.children = List[Self]()

    fn _search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt, mut best_move: MoveScore[G.Move], logger: Logger) -> Score:
        if perf_counter_ns() > deadline:
            return Score.no_score()

        if not self.children:
            var moves = game.moves()
            self.children = List[Self](capacity=len(moves))
            for ref move in moves:
                self.children.append(Self(move.move, move.score))

        var best_score = Score.loss()
        if depth == max_depth:
            for node in self.children:
                best_score = max(best_score, node.score)
            return best_score

        sort[Self.greater](self.children)
        if depth <= trace_level:
            logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        for ref node in self.children:
            if not node.score.is_decisive():
                node.score = Score.no_score()

        for ref node in self.children:
            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " > move: ", node, " [", alpha, ":", beta, "]", sep="")
            if not node.score.is_decisive():
                _ = game.play_move(node.move)
                node.score = -node._search(game, -beta, -alpha, depth + 1, max_depth, deadline, best_move, logger)
                game.undo_move(node.move)
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " < move: ", node, " [", alpha, ":", beta, "]", sep="")
            else:
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " < decisive move: ", node, " [", alpha, ":", beta, "]", sep="")

            if not node.score.is_set():
                return Score.no_score()

            if node.score > best_score:
                best_score = node.score
                if depth == 0:
                    best_move = MoveScore(node.move, node.score)
                    logger.debug("best move", best_move)

            if best_score > beta:
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                return best_score
            
            alpha = max(alpha, node.score)

        if depth <= trace_level:
            logger.trace("|  " * depth, depth, " << search: score: ", best_score, sep="")
        return best_score

    fn write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, depth = 0)
        
    fn write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self.move, " ", self.score, "\n")
        if self.children: # TODO silence the compiler warning
            for child in self.children:
                child.write_to(writer, depth + 1)

    @staticmethod
    @parameter
    fn greater(a: Self, b: Self) -> Bool:
        if a.score.is_set():
            if b.score.is_set():
                return a.score > b.score
            else:
                return True
        else:
            return False

alias first_move: Int = 0
alias zero_window: Int = 1
alias full_window: Int = 2


struct PrincipalVariationNegamax[G: TGame](Negamax):
    alias Game = G

    var best_move: MoveScore[G.Move]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Principal Variation Negamax"

    fn __init__(out self):
        self.best_move = MoveScore[G.Move](G.Move(), Score.no_score())
        self.logger = Logger(prefix="pv: ")

    fn search(mut self, mut game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        _ = self._search(game, Score.loss(), Score.win(), 0, depth, deadline)
        return self.best_move

    fn _search(mut self, mut game: G, var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt) -> Score:
        if perf_counter_ns() > deadline:
            return Score.no_score()

        var best_score = Score.loss()
        var moves = game.moves()
        if depth == max_depth:
            for move in moves:
                if move.score > best_score:
                    best_score = move.score
                    if depth == 0:
                        self.best_move = move
                        self.logger.debug("best move", self.best_move)
            return best_score

        sort[Self.greater](moves)

        var idx = 0
        var state = first_move
        if depth <= trace_level:
            self.logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        while idx < len(moves):
            ref move = moves[idx]
            if move.score.is_decisive():
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " = decisive-move: ", move, " [", alpha, ":", beta, "]", sep="")
                if move.score.is_win():
                    if depth <= trace_level:
                        self.logger.trace("|  " * depth, depth, " << search: win", sep="")
                    return Score.win()
                if move.score > beta:
                    if depth <= trace_level:
                        self.logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                    return move.score

                alpha = max(alpha, move.score)
                idx += 1
                continue

            if state != full_window:
                _ = game.play_move(move.move)

            var b = beta
            if state == zero_window:
                b = alpha
            if depth <= trace_level:
                self.logger.trace("|  " * depth, depth, " > move: ", move.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, sep="")
                    
            move.score = -self._search(game, -b, -alpha, depth + 1, max_depth, deadline)

            if depth <= trace_level:
                self.logger.trace("|  " * depth, depth, " < move: ", move.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, "; score: ", move.score, sep="")

            if not move.score.is_set():
                game.undo_move(move.move)
                if depth <= trace_level:
                    self.logger.trace("|  " * depth, depth, " << search: timeout", sep="")
                return Score.no_score()

            if move.score < alpha:
                state = zero_window
                game.undo_move(move.move)
                idx = idx + 1
            elif move.score <= beta:
                alpha = move.score
                if move.score > best_score:
                    if depth == 0:
                        self.best_move = move
                        self.logger.debug("best move", self.best_move)
                if state == zero_window:
                    state = full_window
                else:
                    state = zero_window
                    game.undo_move(move.move)
                    idx = idx + 1
            else:
                if state == zero_window:
                    state = full_window
                    alpha = move.score
                else:
                    if depth <= trace_level:
                        self.logger.trace("|  " * depth, depth, " << search: cut-score: ", move.score, sep="")
                    game.undo_move(move.move)
                    return move.score
            best_score = max(best_score, move.score)


        if depth <= trace_level:
            self.logger.trace("|  " * depth, depth, " << search: score: ", best_score, sep="")
        return best_score

    @staticmethod
    @parameter
    fn greater(a: MoveScore[Self.G.Move], b: MoveScore[Self.G.Move]) -> Bool:
        return a.score > b.score


from connect6 import Connect6

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
alias timeout = 60_000
# alias timeout = 200


fn main() raises:
    # game = Game()
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

    # game = Game()
    # _ = game.play_move("j10")
    # _ = game.play_move("j9-i10")
    # print("Alpha-Beta Negamax With Memory")
    # move = search[AlphaBetaNegamaxWithMemory[Game]](game, timeout)
    # print("move", move)
    # print()

    alias depth = 5

    # print("Basic Negamax")
    # game = Game()
    # _ = game.play_move("j10")
    # _ = game.play_move("j9-i10")

    # var tree = BasicNegamax[Game]()
    # var start = perf_counter_ns()
    # var move = tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    # print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    print("Alpha-Beta Negamax: depth", depth)
    game = Game()
    _ = game.play_move("j10")
    _ = game.play_move("j9-i10")
    print(game)

    var ab_tree = AlphaBetaNegamax[Game]()
    start = perf_counter_ns()
    var ab_move = ab_tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    print("depth", depth, "move", ab_move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    print()

    print("Principal Variation Negamax")
    game = Game()
    _ = game.play_move("j10")
    _ = game.play_move("j9-i10")

    var pv_tree = PrincipalVariationNegamax[Game]()
    start = perf_counter_ns()
    var pv_move = pv_tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    print("depth", depth, "move", pv_move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    # print("Alpha-Beta Negamax With Memory: depth", depth)
    # game = Game()
    # _ = game.play_move("j10")
    # _ = game.play_move("j9-i10")

    # var abm_tree = AlphaBetaNegamaxWithMemory[Game]()
    # var start = perf_counter_ns()
    # var abm_move = abm_tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    # print("depth", depth, "move", abm_move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

