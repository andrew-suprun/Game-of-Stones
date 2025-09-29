alias debug = 2

from sys import env_get_int
from time import perf_counter_ns

from score import Score
from tree import TTree
from game import TGame


fn search[Tree: TTree](mut tree: Tree, mut game: Tree.Game, duration_ms: Int) -> Tree.Game.Move:
    @parameter
    fn greater(a: (Tree.Game.Move, Score), b: (Tree.Game.Move, Score)) -> Bool:
        return a[1] > b[1]

    var roots = game.moves()
    debug_assert(len(roots) > 0)
    sort[greater](roots)
    if debug > 0:
        print("> search")
        for root in roots:
            print("  > root:", root[0], root[1])

    var (move, score) = roots[0]
    if len(roots) == 1 or score.is_decisive():
        if debug > 0:
            print("< decisive-1:", root[0], root[1])
        return move

    var deadline = perf_counter_ns() + 1_000_000 * duration_ms
    var max_depth = 1
    var idx = 0
    while perf_counter_ns() < deadline:
        var (move, _) = roots[idx]
        game.play_move(move)
        roots[idx][1] = tree.search(game, max_depth, deadline)
        game.undo_move(move)
        idx += 1
        if idx == len(roots):
            max_depth += 1
            idx = 0
            sort[greater](roots)
            var (move, score) = roots[0]
            if score.is_decisive():
                if debug > 0:
                    print("< decisive-2:", root[0], root[1])
                return move

    if debug > 1:
        print("search results: idx:", idx)
        for move, score in roots:
            print("  move", move, score)

    idx = max(1, idx)
    var (best_move, best_score) = roots[0]
    for i in range(idx):
        var (move, score) = roots[i]
        if best_score < score:
            best_score = score
            best_move = move

    return best_move


fn main():
    pass
