from engine import Gomoku, Connect6, Mcts, MoveValue

# comptime Game = Connect6[size=19]
comptime Game = Gomoku[size=19]

comptime Tree = Mcts[Game, 0.7]

comptime script = "j10 i10 j9"


def main() raises:
    var game = Tree.Game()
    var tree = Tree()
    var open_moves = script.split(" ")
    print("opening", script)
    for move_str in open_moves:
        game.play_move({String(move_str)})
    print(game)
    var moves = List[MoveValue[Game.Move]](capacity=16)
    for i in range(1, 101):
        for _ in range(100_000):
            tree.expand(game, 16, moves)

        print(t"--- {i}")
        print(tree._pv())
        print(tree)
