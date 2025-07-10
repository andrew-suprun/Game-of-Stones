from game import Decision
from tree import Tree
from connect6 import Connect6

fn main() raises:
    alias Game = Connect6[19, 6, 6]
    var game = Game()
    var tree = Tree[Game, 30](Game.Score.draw())
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
        if tree.root.decision == Decision.undecided:
            print("best move", move, "score", -tree.root.score)
        else:
            print("best move", move, "decision", tree.root.decision, "result", decision)
        tree.debug_roots()
        tree = Tree[Game, 30](Game.Score.draw())
        print(game)
