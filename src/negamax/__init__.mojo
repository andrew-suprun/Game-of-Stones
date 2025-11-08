from logger import Logger
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore


trait Negamax(Defaultable):
    alias Game: TGame

    @staticmethod
    fn name() -> StaticString:
        ...

    fn search(mut self, game: Self.Game, max_depth: Int, deadline: UInt) -> MoveScore[Self.Game.Move]:
        ...
    

struct Search[N: Negamax](TTree):
    alias Game = N.Game

    var tree: N
    
    @staticmethod
    fn name() -> StaticString:
        return N.name()

    fn __init__(out self):
        self.tree = N()

    fn search(mut self, game: N.Game, duration_ms: UInt) -> MoveScore[N.Game.Move]:
        var logger = Logger(prefix="s:  ")
        var best_move = MoveScore[N.Game.Move](N.Game.Move(), Score.no_score())
        var depth = 1
        var deadline = perf_counter_ns() + UInt(1_000_000) * duration_ms
        while perf_counter_ns() < deadline:
            start = perf_counter_ns()
            var move = self.tree.search(game, depth, deadline)
            if not move.score.is_set():
                break
            logger.info("#", N.name(), "depth", depth, "move", move, "time", (perf_counter_ns() - start) / 1_000_000_000)
            best_move = move
            var g = game.copy()
            var score = g.play_move(move.move)
            if score.is_decisive():
                break
            depth += 1
        return best_move
