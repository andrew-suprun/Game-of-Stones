from engine import Gomoku, Mcts, MoveValue


def main() raises:
    comptime G = Gomoku[size=19, max_plies=100]
    comptime Tree = Mcts[G, 0.35]

    var game = G()
    var tree = Tree()

    game.play_move(G.Move("j10"))
    game.play_move(G.Move("i9"))
    game.play_move(G.Move("i10"))
    var moves = List[MoveValue[G.Move]](capacity=26)

    for i in range(1, 21):
        print(t"==== expand {i}")
        tree.expand(game, 26, moves)
        var pv = tree._pv()
        print(t"pv:", end="")
        for move in pv:
            print(t" {move}", end="")
        print()
        print(repr(tree))
