from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame, MoveScore


alias debug = env_get_int["SEARCH_DEBUG", 0]()


fn search[Tree: Negamax](mut tree: Tree, mut game: Tree.Game, duration_ms: Int) -> MoveScore[Tree.Game.Move]:
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
    var best_root = roots[0]
    while True:
        var first_root = True
        best_root.score = Score.loss()
        for ref root in roots:
            var score = game.play_move(root.move)
            if score.is_set() and not score.is_decisive():
                root.score = -tree.search(game, best_root.score, Score.win(), max_depth, deadline)
                game.undo_move(root.move)

            if not root.score.is_set():
                if debug > 0:
                    print("< best root:", best_root)
                return best_root

            if first_root or root.score > best_root.score:
                best_root = root

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
        var score = Score.loss()
        var moves = game.moves()
        for move in moves:
            var new_score = move.score
            if depth > 0 and not new_score.is_decisive():
                _ = game.play_move(move.move)
                new_score = -self.search(game, lower, upper, depth - 1, deadline)
                game.undo_move(move.move)
                if perf_counter_ns() > deadline:
                    return Score.no_score()
            score = max(score, new_score)

        return score

from connect6 import Connect6

fn main() raises:
    alias Game = Connect6[size=19, max_moves=8, max_places=6, max_plies=100]
    var game = Game()
    var tree = BasicNegamax[Game]()
    _ = game.play_move("j10")
    _ = game.play_move("i9-i10")
    for depth in range(1, 8):
        var start = perf_counter_ns()
        var deadline = start + 4_000_000_000
        var score = tree.search(game, Score.loss(), Score.win(), depth, deadline)
        print("depth", depth, "score", score, "time", Float64(perf_counter_ns() - start) / 1_000_000_000)
        # print("----")
        # var move2 = tree2.search(game, 20_000)
        # print("nmax", move2)

        # var result = game.play_move(move2.move)
        # print(game)

        # if result.is_decisive():
        #     break
        # break
