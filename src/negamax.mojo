from value import Value, Win, Draw, Loss, is_win, is_loss, is_draw
from traits import TGame


def search[Game: TGame](game: Game, depth: Int) -> Value:
    var best_score = Loss
    var moves = game.moves()
    if depth == 0:
        for move in moves:
            best_score = max(best_score, move.value)
        return best_score

    for mv in moves:
        if is_win(mv.value):
            return Win
        elif is_loss(mv.value):
            continue
        elif is_draw(mv.value):
            best_score = max(best_score, 0)
        else:
            var g = game.copy()
            g.play_move(mv.move)
            var child_score = search(g, depth - 1)
            best_score = max(best_score, -child_score)
    return best_score
