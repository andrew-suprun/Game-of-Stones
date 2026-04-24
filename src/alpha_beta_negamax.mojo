from std.time import perf_counter_ns
from std.logger import Logger

from score import Score
from traits import TTree, TGame, MoveScore


struct AlphaBetaNegamax[G: TGame](TTree):
    comptime Game = Self.G
    comptime MoveScore = MoveScore[Self.G.Move]

    var root: AlphaBetaNode[Self.G]
    var logger: Logger[]

    @staticmethod
    def name() -> StaticString:
        return "Alpha-Beta Negamax With Memory"

    def __init__(out self):
        self.root = AlphaBetaNode[Self.G]({}, {})
        self.logger = Logger(prefix="abs: ")

    def search(mut self, game: Self.G, duration_ms: UInt) -> Self.MoveScore:
        var best_move: Self.MoveScore = {{}, Score.loss()}
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        var start = perf_counter_ns()
        while True:
            var score = self.root._search(game, best_move, Score.loss(), Score.win(), 0, depth, deadline, self.logger)
            if not score.is_set():
                return best_move
            self.logger.debug("=== max depth: ", depth, " move:", best_move, " time:", Float64(perf_counter_ns() - start) / 1_000_000_000)
            if best_move.score.is_decisive():
                return best_move
            depth += 1


struct AlphaBetaNode[G: TGame](Copyable, Writable):
    var move: Self.G.Move
    var score: Score
    var children: List[Self]

    def __init__(out self, move: Self.G.Move, score: Score):
        self.move = move
        self.score = score
        self.children = List[Self]()

    def _search(mut self, game: Self.G, mut best_move: MoveScore[Self.G.Move], var alpha: Score, beta: Score, depth: Int, max_depth: Int, deadline: UInt, logger: Logger) -> Score:
        if perf_counter_ns() > deadline:
            return Score()

        if not self.children:
            self.children = [Self(move.move, move.score) for move in game.moves()]

        best_move = {self.children[0].move, self.children[0].score}

        var best_score = Score.loss()
        if depth == max_depth:
            for child in self.children:
                best_score = max(best_score, child.score)
            return best_score

        sort[Self.greater](self.children)

        var deeper_best_move: MoveScore[Self.G.Move] = {{}, 0}
        for ref child in self.children:
            if not child.score.is_decisive():
                child.score = Score()

        for ref child in self.children:
            var g = game.copy()
            if not child.score.is_decisive():
                _ = g.play_move(child.move)
                child.score = -child._search(g, deeper_best_move, -beta, -alpha, depth + 1, max_depth, deadline, logger)

            if not child.score.is_set():
                return Score()

            if child.score > best_score:
                best_score = child.score
                best_move = {child.move, child.score}

            if best_score > beta or best_score.is_win():
                return best_score

            alpha = max(alpha, child.score)

        return best_score

    def write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, depth=0)

    def write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, self.move, " ", self.score, "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_to(writer, depth + 1)

    @staticmethod
    @parameter
    def greater(a: Self, b: Self) -> Bool:
        return a.score > b.score