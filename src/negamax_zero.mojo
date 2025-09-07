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
        print("bounds:", lower_bound, "..", upper_bound, "\n====")

    print("\n<< mtdf: guess", guess)
    return guess


fn negamax_zero[Game: TGame](mut game: Game, guess: Score, depth: Int, max_depth: Int) -> Score:
    @parameter
    fn greater(a: MoveScore[Game.Move], b: MoveScore[Game.Move]) -> Bool:
        return a.score > b.score

    if depth == max_depth:
        var move = game.move()
        if debug:
            print("|   " * depth, "leaf:", move)
        return move.score

    var children = game.moves()

    debug_assert(len(children) > 0)

    var best_score = Score.loss()

    sort[greater](children)

    for ref child in children:
        if debug:
            print("|   " * depth + "> move", child.move)
        if not child.score.is_decisive():
            _ = game.play_move(child.move)
            child.score = -negamax_zero(game, -guess, depth + 1, max_depth)
            game.undo_move(child.move)

        if child.score > best_score:
            best_score = child.score
            if depth == 0:
                if debug:
                    print("### best move", child)

        if debug:
            print("|   " * depth + "< move", child.move, best_score)
        if child.score > guess:
            if debug:
                print("|   " * depth + "cut-off:", child.score, ">", guess)
            return best_score

    return best_score
