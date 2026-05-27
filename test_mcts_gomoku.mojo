from engine import Gomoku, Mcts, Score


def main() raises:
    comptime G = Gomoku[size=19, max_moves=26]
    comptime Tree = Mcts[G, Score(0.35)]

    var game = G()
    var tree = Tree()

    game.play_move(G.Move("j10"))
    game.play_move(G.Move("i9"))
    game.play_move(G.Move("i10"))

    for i in range(1, 21):
        print(t"==== expand {i}")
        tree.expand(game)
        var pv = tree._pv()
        print(t"pv:", end="")
        for move in pv:
            print(t" {move}", end="")
        print()
        print(repr(tree))
