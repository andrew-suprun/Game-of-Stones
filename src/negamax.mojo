from score import Score, Win, Draw, Loss
from traits import TGame


def search[Game: TGame](game: Game, depth: Int) -> Score:
    var best_score = Loss
    var moves = game.moves()
    if depth == 0:
        for move in moves:
            best_score = max(best_score, move.score())
        return best_score

    for move in moves:
        if move.score().is_win():
            return Win
        elif move.score().is_loss():
            continue
        elif move.score().is_draw():
            best_score = max(best_score, 0)
        else:
            var g = game.copy()
            g.play_move(move)
            var child_score = search(g, depth - 1)
            best_score = max(best_score, -child_score)
    return best_score
