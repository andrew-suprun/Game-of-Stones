from score import Score, Draw, Loss, max_score, is_draw, is_decisive
from traits import TGame


def search[Game: TGame](game: Game, depth: Int) -> Score:
    var best_score = Loss
    var moves = game.moves()
    if depth == 0:
        for move in moves:
            best_score = max_score(best_score, move.score())
        return best_score

    for move in moves:
        if is_decisive(move.score()):
            return move.score()
        var g = game.copy()
        g.play_move(move)
        var child_score = search(g, depth - 1)
        var score = Draw if is_draw(child_score) else 0 if child_score == 0 else -child_score
        best_score = max_score(best_score, score)
    return best_score
