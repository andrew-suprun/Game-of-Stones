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
        var score = game.play_move(move.move)
        game.undo_move(move.move)
        if score.is_decisive():
            break
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
            elif depth == 0:
                self.logger.debug("     move", move)

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
            for move in moves:
                self.children.append(Self(move.move, move.score))

        var best_score = Score.loss()
        if depth == max_depth:
            for child in self.children:
                best_score = max(best_score, child.score)
            return best_score

        sort[Self.greater](self.children)
        if depth <= trace_level:
            logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        for ref child in self.children:
            if not child.score.is_decisive():
                child.score = Score.no_score()

        for ref child in self.children:
            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " > move: ", child.move, " [", alpha, ":", beta, "]", sep="")
            if not child.score.is_decisive():
                _ = game.play_move(child.move)
                child.score = -child._search(game, -beta, -alpha, depth + 1, max_depth, deadline, best_move, logger)
                game.undo_move(child.move)
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " < move: ", child.move, " [", alpha, ":", beta, "] score: ", child.score, sep="")
            else:
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " < decisive move: ", child.move, " ", child.score, " [", alpha, ":", beta, "]", sep="")

            if not child.score.is_set():
                return Score.no_score()

            if child.score > best_score:
                best_score = child.score
                if depth == 0:
                    best_move = MoveScore(child.move, child.score)
                    logger.debug("best move", best_move)
            elif depth == 0:
                logger.debug("     move", child.move, child.score)

            if best_score > beta:
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                return best_score
            
            alpha = max(alpha, child.score)

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
                best_score = max(best_score, move.score)
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
                    if depth == 0:
                        self.best_move = MoveScore[G.Move](move.move, Score.win())
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
                if depth == 0:
                    self.logger.debug("     move", move)
                state = zero_window
                game.undo_move(move.move)
                idx = idx + 1
            elif move.score <= beta:
                if move.score > best_score:
                    if depth == 0:
                        self.best_move = move
                        self.logger.debug("best move", self.best_move)
                elif depth == 0:
                    self.logger.debug("     move", move)
                if state == zero_window and move.score > alpha:
                    state = full_window
                else:
                    state = zero_window
                    game.undo_move(move.move)
                    idx = idx + 1
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


struct PrincipalVariationNegamaxWithMemory[G: TGame](Negamax):
    alias Game = G

    var root: PrincipalVariationNode[G]
    var best_move: MoveScore[G.Move]
    var logger: Logger

    @staticmethod
    fn name() -> StaticString:
        return "Principal Variation Negamax With Memory"

    fn __init__(out self):
        self.root = PrincipalVariationNode[G](G.Move(), Score.no_score())
        self.best_move = MoveScore[G.Move](G.Move(), Score.no_score())
        self.logger = Logger(prefix="pv+: ")

    fn search(mut self, mut game: G, depth: Int, deadline: UInt) -> MoveScore[G.Move]:
        debug_assert(depth >= 1)
        _ = self.root._search(game, Score.loss(), Score.win(), 0, depth, deadline, self.best_move, self.logger)
        return self.best_move


struct PrincipalVariationNode[G: TGame](Copyable, Movable, Writable):
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
            for move in moves:
                self.children.append(Self(move.move, move.score))

        var best_score = Score.loss()
        if depth == max_depth:
            for child in self.children:
                best_score = max(best_score, child.score)
            return best_score

        sort[Self.greater](self.children)

        if depth <= trace_level:
            logger.trace("|  " * depth, depth, " >> search [", alpha, ":", beta, "]", sep="")

        for ref child in self.children:
            if not child.score.is_decisive():
                child.score = Score.no_score()

        var idx = 0
        var state = first_move
        while idx < len(self.children):
            ref child = self.children[idx]
            if child.score.is_decisive():
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " = decisive-move: ", child.move, " ", child.score, " [", alpha, ":", beta, "]", sep="")
                if child.score.is_win():
                    if depth <= trace_level:
                        logger.trace("|  " * depth, depth, " << search: win", sep="")
                    if depth == 0:
                        best_move = MoveScore[G.Move](child.move, Score.win())
                    return Score.win()
                if child.score > beta:
                    if depth <= trace_level:
                        logger.trace("|  " * depth, depth, " << search: cut-score: ", best_score, sep="")
                    return child.score

                alpha = max(alpha, child.score)
                idx += 1
                continue

            if state != full_window:
                _ = game.play_move(child.move)

            var b = beta
            if state == zero_window:
                b = alpha
            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " > move: ", child.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, sep="")
                    
            child.score = -child._search(game, -b, -alpha, depth + 1, max_depth, deadline, best_move, logger)

            if depth <= trace_level:
                logger.trace("|  " * depth, depth, " < move: ", child.move, " [", alpha, ":", b, "]; beta: ", beta, "; state: ", state, "; score: ", child.score, sep="")

            if not child.score.is_set():
                game.undo_move(child.move)
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " << search: timeout", sep="")
                return Score.no_score()

            if child.score < alpha:
                if depth == 0:
                    logger.debug("     move", child.move, child.score)
                state = zero_window
                game.undo_move(child.move)
                idx = idx + 1
            elif child.score <= beta:
                if child.score > best_score:
                    if depth == 0:
                        best_move = MoveScore[G.Move](child.move, child.score)
                        logger.debug("best move", best_move)
                elif depth == 0:
                    logger.debug("     move", child.move, child.score)
                if state == zero_window and child.score > alpha:
                    state = full_window
                else:
                    state = zero_window
                    game.undo_move(child.move)
                    idx = idx + 1
                alpha = child.score
            else:
                if depth <= trace_level:
                    logger.trace("|  " * depth, depth, " << search: cut-score: ", child.score, sep="")
                game.undo_move(child.move)
                return child.score
            best_score = max(best_score, child.score)


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


from connect6 import Connect6
alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]

# from gomoku import Gomoku
# alias Game = Gomoku[size=19, max_places=20, max_plies=100]

# alias timeout = 300_000
# alias timeout = 120_000
# alias timeout = 60_000
alias timeout = 1000

alias m1 = "j10"
alias m2 = "j9-i11"
# alias m2 = "i8"

fn main() raises:
    game = Game()
    _ = game.play_move(m1)
    _ = game.play_move(m2)
    print(game)
    print("Basic Negamax")
    var move = search[BasicNegamax[Game]](game, timeout)
    print("move", move)
    print()

    game = Game()
    _ = game.play_move(m1)
    _ = game.play_move(m2)
    print("Alpha-Beta Negamax")
    move = search[AlphaBetaNegamax[Game]](game, timeout)
    print("move", move)
    print()

    game = Game()
    _ = game.play_move(m1)
    _ = game.play_move(m2)
    print("Principal Variation Negamax")
    move = search[PrincipalVariationNegamax[Game]](game, timeout)
    print("move", move)
    print()

    game = Game()
    _ = game.play_move(m1)
    _ = game.play_move(m2)
    print("Alpha-Beta Negamax With Memory")
    move = search[AlphaBetaNegamaxWithMemory[Game]](game, timeout)
    print("move", move)
    print()

    game = Game()
    _ = game.play_move(m1)
    _ = game.play_move(m2)
    print("Principal Variation Negamax With Memory")
    move = search[PrincipalVariationNegamaxWithMemory[Game]](game, timeout)
    print("move", move)
    print()

    ########################

    alias depth = 6

    # print("Basic Negamax")
    # game = Game()
    # _ = game.play_move(m1)
    # _ = game.play_move(m2)
    # var tree = BasicNegamax[Game]()
    # start = perf_counter_ns()
    # move = tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    # print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    # print("Alpha-Beta Negamax: depth", depth)
    # game = Game()
    # _ = game.play_move(m1)
    # _ = game.play_move(m2)
    # var ab_tree = AlphaBetaNegamax[Game]()
    # start = perf_counter_ns()
    # move = ab_tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    # print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    # print("Alpha-Beta Negamax With Memory: depth", depth)
    # game = Game()
    # _ = game.play_move(m1)
    # _ = game.play_move(m2)
    # var abm_tree = AlphaBetaNegamaxWithMemory[Game]()
    # start = perf_counter_ns()
    # move = abm_tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    # print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    # print("Principal Variation Negamax")
    # game = Game()
    # _ = game.play_move(m1)
    # _ = game.play_move(m2)
    # var pv_tree = PrincipalVariationNegamax[Game]()
    # start = perf_counter_ns()
    # move = pv_tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    # print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    # print()

    # print("Principal Variation Negamax With Memory: depth", depth)
    # game = Game()
    # _ = game.play_move(m1)
    # _ = game.play_move(m2)
    # # print(game)
    # var pvm_tree = PrincipalVariationNegamaxWithMemory[Game]()
    # start = perf_counter_ns()
    # move = pvm_tree.search(game, depth, perf_counter_ns() + 120_000_000_000)
    # print("depth", depth, "move", move, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)

    
