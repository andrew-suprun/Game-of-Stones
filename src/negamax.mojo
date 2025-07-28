from builtin.sort import sort

from game import TGame, Score, loss

struct Negamax[Game: TGame]:
    fn expand(mut self, mut game: Game, alpha: Score, beta: Score, depth: Int) -> (Game.Move, Score):
        var a = alpha
        var b = beta
        if depth == 0: return game.best_move()
        var best_move = Game.Move()
        var best_score = Score()
        var moves = game.moves()
        sort[grater[Game]](moves)
        for (child_move, _) in moves:
            game.play_move(child_move)
            var (_, score) = self.expand(game, -b, -a, depth - 1)
            score = -score
            game.undo_move(child_move)
            if score > best_score:
                best_move = child_move
                if score > alpha:
                    a = score
            if score > b:
                return (child_move, loss)
        return (best_move, best_score)

fn grater[Game: TGame](a: (Game.Move, Score), b: (Game.Move, Score)) capturing -> Bool:
    return a[1] > b[1]