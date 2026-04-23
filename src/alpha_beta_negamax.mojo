from std.time import perf_counter_ns
from std.sys.defines import get_defined_string

from traits import TTree, TGame, Score
from logging import debug

comptime logging_level = get_defined_string["LOGGING_LEVEL", "NOTSET"]()


struct AlphaBetaNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: AlphaBetaNode[Self.G]

    def __init__(out self):
        self.root = AlphaBetaNode[Self.G]({})

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * max_time_ms
        var start = perf_counter_ns()
        while True:
            if self.root._search(game, -Self.G.Win, Self.G.Win, 0, depth, deadline):
                return self._pv()

            comptime if logging_level == "DEBUG" or logging_level == "TRACE":
                var time = Float64(perf_counter_ns() - start) / 1_000_000_000
                print("=== max depth: ", depth, " move:", repr(self._pv()[0]), " time:", time)

            var pv = self._pv()
            if pv[0].is_decisive():
                return pv^

            var n_undecided = 0
            for child in self.root.children:
                if not child.move.is_decisive():
                    n_undecided += 1

            if n_undecided == 1:
                return pv^
            depth += 1

    def _pv(self) -> List[Self.G.Move]:
        var pv = List[Self.G.Move]()
        self.root._pv(pv)
        return pv^


struct AlphaBetaNode[G: TGame](Copyable, Writable):
    var move: Self.G.Move
    var children: List[Self]

    def __init__(out self, move: Self.G.Move):
        self.move = move
        self.children = List[Self]()

    def _search(
        mut self,
        game: Self.G,
        var alpha: Score,
        beta: Score,
        depth: Int,
        max_depth: Int,
        deadline: UInt,
        out done: Bool,
    ):
        # comptime if logging_level == "TRACE":
        #     print("   "*depth, t">> {depth} [{alpha} : {beta}] self: {self.move}")

        if perf_counter_ns() > deadline:
            done = True            
            # comptime if logging_level == "TRACE":
            #     print("   "*depth, t"<< {depth} [{alpha} : {beta}]: time out: self: {repr(self.move)}")
            return

        done = False

        if not self.children:
            var moves = game.moves()
            assert len(moves) > 0
            self.children = [Self(move) for move in moves]

        var child_best_score = -Self.G.Win
        var all_decisive = True
        if depth == max_depth:
            for ref child in self.children:
                child_best_score = max(child_best_score, child.move.score())
                if not child.move.is_decisive():
                    all_decisive = False
            self.move.set_score(-child_best_score)
            if all_decisive:
                self.move.set_decisive()
            # comptime if logging_level == "TRACE":
            #     print("   "*depth, t"<< {depth} [{alpha} : {beta}]: max depth: self: {repr(self.move)}")
            return

        sort[Self.greater](self.children)

        for ref child in self.children[1:]:
            if not child.move.is_decisive():
                child.move.set_score(-Self.G.Win)

        comptime if logging_level == "TRACE":
            print("   "*depth, t"== {depth} [{alpha} : {beta}] self: {self.move}")

        for ref child in self.children:
            if not child.move.is_decisive():
                var g = game.copy()
                g.play_move(child.move)
                comptime if logging_level == "TRACE":
                    print("   "*depth, t">> {depth} [{alpha} : {beta}] self: {self.move} child: {child.move}")
                done = child._search(g, -beta, -alpha, depth + 1, max_depth, deadline)
                child_best_score = max(child_best_score, child.move.score())
                comptime if logging_level == "TRACE":
                    print("   "*depth, t"<< {depth} [{alpha} : {beta}] self: {self.move} child: {repr(child.move)}")
                if done:
                    break

            if alpha < child_best_score:
                alpha = child_best_score
                comptime if logging_level == "TRACE":
                    print("   "*depth, t"== {depth} new alpha: {alpha} self: {self.move}")

            if alpha >= beta or alpha >= Self.G.Win:
                comptime if logging_level == "TRACE":
                    print("   "*depth, t"== {depth} [{alpha} : {beta}] beta cut: self: {self.move}")
                break

        self.move.set_score(-child_best_score)
        for ref child in self.children:
            comptime if logging_level == "DEBUG" or logging_level == "TRACE":
                assert child.move.is_decisive() ^ (child.move.score() <= -Self.G.Win or child.move.score() >= Self.G.Win)
            if child.move.is_decisive():
                if child.move.score() > 0:
                    self.move.set_decisive()
                    break
            else:
                all_decisive = False

        if all_decisive:
            self.move.set_decisive()

        comptime if logging_level == "TRACE":
            print("   "*depth, t"++ {depth}: self: {repr(self.move)}")
            for child in self.children:
                print("   "*depth, t"++ {depth}: child: {repr(child.move)}")

        comptime if logging_level == "DEBUG" or logging_level == "TRACE":
            assert self.move.is_decisive() ^ (self.move.score() <= -Self.G.Win or self.move.score() >= Self.G.Win)


    def _pv(self, mut pv: List[Self.G.Move]):
        if not self.children:
            return

        ref best_child = self._best_node()
        pv.append(best_child.move)
        best_child._pv(pv)

    def _best_node(self) -> ref[self.children] Self:
        var best_child_idx = 0
        for idx in range(len(self.children)):
            ref child = self.children[idx]
            if child.move.is_decisive():
                if child.move.score() < 0:
                    continue
                elif child.move.score() > 0:
                    return child

            if self.children[best_child_idx].move.score() < child.move.score():
                best_child_idx = idx

        return self.children[best_child_idx]

    def write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, depth=0)

    def write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, repr(self.move), "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_to(writer, depth + 1)

    @staticmethod
    @parameter
    def greater(a: Self, b: Self) -> Bool:
        return a.move.score() > b.move.score()
