from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore


alias debug = env_get_int["SEARCH_DEBUG", 0]()


fn search[Tree: TTree](mut tree: Tree, mut game: Tree.Game, duration_ms: Int) -> MoveScore[Tree.Game.Move]:
    @parameter
    fn greater(a: MoveScore[Tree.Game.Move], b: MoveScore[Tree.Game.Move]) -> Bool:
        return a.score > b.score

    var roots = game.moves()
    sort[greater](roots)
    debug_assert(len(roots) > 0)
    if len(roots) == 1 or roots[0].score.is_decisive():
        if debug > 0:
            print("< decisive:", roots[0])
        return roots[0]

    var deadline = perf_counter_ns() + 1_000_000 * duration_ms
    var max_depth = 1
    while True:
        for idx in range(len(roots)):
            ref root = roots[idx]
            var score = game.play_move(root.move)
            if score.is_set() and not score.is_decisive():
                root.score = -tree.search(game, max_depth, deadline)
                game.undo_move(root.move)
            if not root.score.is_set():
                if debug > 1:
                    print("search results: idx:", idx)
                    for root in roots:
                        print("  root", root)
                var best_root = roots[0]
                for i in range(idx):
                    if best_root.score < roots[i].score:
                        best_root = roots[i]
                return best_root
        max_depth += 1
        sort[greater](roots)
        if roots[0].score.is_decisive():
            if debug > 0:
                print("< decisive-2:", roots[0])
            return roots[0]


trait Negamax:
    alias Game: TGame

    fn search(mut self, mut game: Self.Game, lower: Score, upper: Score, max_depth: Int, deadline: UInt) -> Score:
        ...

@fieldwise_init
struct BasicNegamax[G: TGame](Negamax):
    alias Game = G

    fn search(mut self, mut game: G, lower: Score, upper: Score, depth: Int, deadline: UInt) -> Score:
        if perf_counter_ns() > deadline:
            return Score.no_score()
        var score = Score.loss()
        var moves = game.moves()
        for move in moves:
            var new_score = move.score
            if depth > 0 and not new_score.is_decisive():
                _ = game.play_move(move.move)
                new_score = -self.search(game, lower, upper, depth - 1, deadline)
                game.undo_move(move.move)
            score = max(score, new_score)

        return score

fn main():
    pass
