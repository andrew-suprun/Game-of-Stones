from game import draw, isdecisive, score_str
from mcts import MCTS
from connect6 import Connect6

fn main() raises:
    alias Game = Connect6[19, 6, 6]
    var game = Game()
    var tree = MCTS[Game, 30](draw)
    game.play_move("j10")
    game.play_move("i9-i10")
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
        tree = MCTS[Game, 30](draw)
        print(game)
