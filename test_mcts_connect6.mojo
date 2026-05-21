from game_of_stones import Connect6, Mcts, MoveValue


def main() raises:
    comptime C6 = Connect6[size=19, max_plies=100]
    comptime Tree = Mcts[C6, 0.35]

    var game = C6()
    var tree = Tree()

    game.play_move(C6.Move("j10"))
    game.play_move(C6.Move("i9-i10"))
    var moves = List[MoveValue[C6.Move]](capacity=26)

    for i in range(1, 21):
        print(t"==== expand {i}")
        tree.expand(game, 26, moves)
        var pv = tree._pv()
        print(t"pv:", end="")
        for move in pv:
            print(t" {move}", end="")
        print()
        print(repr(tree))
