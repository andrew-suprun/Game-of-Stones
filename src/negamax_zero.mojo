from sys import env_get_bool

from score import Score
from game import TGame, MoveScore


alias debug = env_get_bool["DEBUG", False]()


fn mtdf[Game: TGame](mut game: Game, var guess: Score, max_depth: Int) -> Score:
    print("\n>> mtdf: guess", guess)
    var upper_bound = Score.win()
    var lower_bound = Score.loss()

    while lower_bound < upper_bound:
        var beta = max(guess, lower_bound)
        guess = negamax_zero(game, guess, 0, max_depth)
        if guess <= beta:
            upper_bound = guess
        if guess >= beta:
            lower_bound = guess
        print("\n   mtdf: bounds", lower_bound, upper_bound)

    print("\n<< mtdf: guess", guess)
    return guess


fn negamax_zero[Game: TGame](mut game: Game, guess: Score, max_depth: Int) -> Score:
    print("### negamax", "guess", guess)
    return _negamax_zero(game, guess, 0, max_depth)


fn _negamax_zero[Game: TGame](mut game: Game, var guess: Score, depth: Int, max_depth: Int) -> Score:
    var best_score = Score.loss()
    for move in game.moves():
        var score = game.play_move(move.move)
        if depth < max_depth and not score.is_decisive():
            score = -_negamax_zero(game, guess, depth+1, max_depth)
        print("move", move.move, "guess", guess, "score", score, "best_score", best_score)
        if best_score < score:
            best_score = score
            if guess <= score:
                guess = score
                if depth == 0:
                    print("best move", move.move, "score", score)
        
        if guess < score:
            print("cutoff")
            game.undo_move(move.move)
            return best_score

        game.undo_move(move.move)

    return best_score


fn negamax[Game: TGame](mut game: Game, var alpha: Score, beta: Score, depth: Int, max_depth: Int) -> Score:
    @parameter
    fn greater(a: MoveScore[Game.Move], b: MoveScore[Game.Move]) -> Bool:
        return a.score > b.score

    if depth == max_depth:
        var move = game.move()
        if debug:
            print("\n#" + "|   " * depth + "leaf: move", move, end="")
        return move.score

    var children = game.moves()

    debug_assert(len(children) > 0)

    var best_score = Score.loss()

    # sort[greater](children)

    for ref child in children:
        if debug:
            print("\n#" + "|   " * depth + "> move", child.move, child.score, end="")
        if not child.score.is_decisive():
            _ = game.play_move(child.move)
            child.score = -negamax(game, -beta, -alpha, depth + 1, max_depth)
            game.undo_move(child.move)

        if child.score > best_score:
            best_score = child.score
            if child.score > alpha:
                alpha = child.score

            if depth == 0:
                print("\n### best_move", child, end="")
                if debug:
                    print("\n#|   set best move", child, end="")

        if debug:
            print("\n#" + "|   " * depth + "< move", child.move, child.score, "| best score", best_score, end="")
        if child.score > beta:
            if debug:
                print("\n#" + "|   " * depth + "cut-off", end="")
            return best_score

    if debug:
        print("\n#" + "|   " * depth + "<-- search: best score", best_score, end="")
    return best_score

fn negamax_zero[Game: TGame](mut game: Game, guess: Score, depth: Int, max_depth: Int) -> Score:
    @parameter
    fn greater(a: MoveScore[Game.Move], b: MoveScore[Game.Move]) -> Bool:
        return a.score > b.score

    if depth == max_depth:
        var move = game.move()
        if debug:
            print("\n#" + "|   " * depth + "leaf: move", move, end="")
        return move.score

    var children = game.moves()

    debug_assert(len(children) > 0)

    var best_score = Score.loss()

    # sort[greater](children)

    for ref child in children:
        if debug:
            print("\n#" + "|   " * depth + "> move", child.move, child.score, end="")
        if not child.score.is_decisive():
            _ = game.play_move(child.move)
            child.score = -negamax_zero(game, -guess, depth + 1, max_depth)
            game.undo_move(child.move)

        if child.score > best_score:
            best_score = child.score
            if depth == 0:
                print("\n### best_move", child, end="")
                if debug:
                    print("\n#|   set best move", child, end="")

        if debug:
            print("\n#" + "|   " * depth + "< move", child.move, child.score, "| best score", best_score, end="")
        if child.score > guess:
            if debug:
                print("\n#" + "|   " * depth + "cut-off", end="")
            return best_score

    if debug:
        print("\n#" + "|   " * depth + "<-- search: best score", best_score, end="")
    return best_score
