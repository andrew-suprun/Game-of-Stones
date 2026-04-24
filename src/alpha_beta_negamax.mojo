from std.time import perf_counter_ns
from std.sys.defines import get_defined_string

from traits import TTree, TGame, Score
from logging import debug

comptime logging_level = get_defined_string["LOGGING_LEVEL", "NOTSET"]()
comptime assert_mode = get_defined_string["ASSERT", "none"]()


struct AlphaBetaNegamax[G: TGame](TTree):
    comptime Game = Self.G

    var root: AlphaBetaNode[Self.G]

    def __init__(out self):
        self.root = AlphaBetaNode[Self.G]({}, 0)

    def search(mut self, game: Self.G, max_time_ms: UInt) -> List[Self.G.Move]:
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * max_time_ms
        var start = perf_counter_ns()
        while True:
            var done = self.root._search(game, -Self.G.Win, Self.G.Win, 0, depth, deadline)
            comptime if assert_mode == "all":
                self.root._validate()

            if done:
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
    var max_depth: Int
    var children: List[Self]

    def __init__(out self, move: Self.G.Move, max_depth: Int):
        self.move = move
        self.max_depth = max_depth
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
        comptime if logging_level == "TRACE":
            print("   "*depth, t">> {depth} [{alpha} : {beta}] self: {self.move}")

        if perf_counter_ns() > deadline:
            done = True            
            comptime if logging_level == "TRACE":
                print("   "*depth, t"<< {depth} [{alpha} : {beta}]: time out: self: {repr(self.move)}")
            return

        done = False

        if not self.children:
            var moves = game.moves()
            assert len(moves) > 0
            self.children = [Self(move, max_depth) for move in moves]

        var best_child_score = Score.MIN
        var decisive = True
        if depth == max_depth:
            for ref child in self.children:
                best_child_score = max(best_child_score, child.move.score())
                if child.move.is_decisive():
                    if child.move.score() > 0:
                        self.move.set_decisive()
                else:
                    decisive = False
            self.move.set_score(-best_child_score)
            self.max_depth = max_depth
            if decisive:
                self.move.set_decisive()
            comptime if logging_level == "TRACE":
                print("   "*depth, t"<< {depth} [{alpha} : {beta}]: max depth: self: {repr(self.move)}")
            return

        sort[Self.greater](self.children)

        comptime if logging_level == "TRACE":
            print("   "*depth, t"== {depth} [{alpha} : {beta}]: moves [{len(self.children)}]: ", end = "")
            for child in self.children:
                print(t"{repr(child.move)}, ", end = "")
            print()

        for ref child in self.children:
            if not child.move.is_decisive():
                var g = game.copy()
                g.play_move(child.move)
                done = child._search(g, -beta, -alpha, depth + 1, max_depth, deadline)

            best_child_score = max(best_child_score, child.move.score())

            if done:
                break

            comptime if logging_level == "TRACE":
                print("   "*depth, t"== {depth} best_child_score: {best_child_score}, self: {self.move}, child: {child.move}")

            if alpha < best_child_score:
                alpha = best_child_score
                comptime if logging_level == "TRACE":
                    print("   "*depth, t"== {depth} new alpha: {alpha}, self: {self.move}, child: {child.move}")

            if alpha >= beta:
                comptime if logging_level == "TRACE":
                    print("   "*depth, t"== {depth} [{alpha} : {beta}] beta cut: self: {self.move}, child: {child.move}")
                break

        self.move.set_score(-best_child_score)
        self.max_depth = max_depth
        for ref child in self.children:
            # comptime if assert_mode == "all":
            #     assert child.move.is_decisive() ^ (child.move.score() <= -Self.G.Win or child.move.score() >= Self.G.Win)
            if child.move.is_decisive():
                if child.move.score() > 0:
                    self.move.set_decisive()
                    break
            else:
                decisive = False

        if decisive:
            self.move.set_decisive()

        comptime if logging_level == "TRACE":
            print("   "*depth, t"<< {depth} [{alpha} : {beta}]: self: {repr(self.move)}, best child score: {best_child_score}")
            for child in self.children:
                print("   "*depth, t"++ {depth}: child: {repr(child.move)}")

        comptime if assert_mode == "all":
            self._validate()

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

    def _validate(self):
        var moves: List[Self.G.Move] = []
        self._validate(moves)

    def _validate(self, mut moves: List[Self.G.Move]):
        var score = self.move.score()
        if self.move.is_decisive():
            if score > -Self.G.Win and score < Self.G.Win and score != 0:
                print("inconsistency: is_decisive: {self.move.is_decisive()}, score: {score}")
                assert False
        
        if self.children:
            var best_score = Score.MIN
            var has_win = False
            var all_decided = True
            for child in self.children:
                best_score = max(best_score, child.move.score())

                var score = child.move.score()
                if child.move.is_decisive():
                    if score > -Self.G.Win and score < Self.G.Win and score != 0:
                        print("inconsistency: is_decisive: {child.move.is_decisive()}, score: {score}")
                        assert False

                if child.move.is_decisive():
                    if score > 0:
                        has_win = True
                else:
                    all_decided = False

            var decisive = all_decided or has_win

            if -self.move.score() > best_score or self.move.is_decisive() != decisive:
                print(t"best score: {best_score}, decisive: {decisive}, self: {repr(self.move)}, pass: ", end="")
                for move in moves:
                    print(t"{repr(move)}, ", end="")
                print(t"children: ", end = "")
                for child in self.children:
                    print(t"{repr(child.move)}, ", end="")
                print()
                assert False

            for child in self.children:
                moves.append(child.move)
                child._validate(moves)
                _ = moves.pop()

    def write_to[W: Writer](self, mut writer: W):
        self.write_to(writer, depth=0)

    def write_to[W: Writer](self, mut writer: W, depth: Int):
        writer.write("|   " * depth, repr(self.move), " [", self.max_depth, "]", "\n")
        if self.children:  # TODO silence the compiler warning
            for child in self.children:
                child.write_to(writer, depth + 1)

    @staticmethod
    @parameter
    def greater(a: Self, b: Self) -> Bool:
        if a.max_depth > b.max_depth:
            return True
        elif a.max_depth < b.max_depth:
            return False
        else:
            return a.move.score() > b.move.score()
