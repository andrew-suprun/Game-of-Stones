from mcts import MCTS
from game import Score, draw, isdecisive, score_str
from gomoku import Gomoku, Move
from board import Place

alias max_moves = 8
alias c = 0
alias Game = Gomoku[19, max_moves]

fn main() raises:
    var title = String.write(max_moves,  "-", c)
    print(title)
    var game = Game()
    var tree = MCTS[Game, c](draw)
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("g9")
    game.play_move("h9")

    print(game)
    var decision: String = "no-decision"
    while decision == "no-decision":
        for _ in range(1, 1000):
            _ = tree.expand(game)
        # print(tree)
        var move = tree.best_move()
        game.play_move(move)
        decision = game.decision()
        for node in tree.roots:
            if isdecisive(node.score):
                print("best move", move, "score", node.score)
            else:
                print("best move", move, "decision", score_str(node.score), "result", decision)
        print(tree.debug_roots())
        tree = MCTS[Game, c](draw)
        print(game)
