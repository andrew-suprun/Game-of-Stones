from std.testing import assert_true

from score import Score
from traits import TGame, TTree

from mcts import Mcts, Node
from gomoku import Gomoku

comptime Game = Gomoku[19, 8, 100]


def main() raises:
    var game = Game()
    var root = Node[Game, 16]()
    game.play_move("j10")
    game.play_move("i9")
    game.play_move("i10")
    print(game)
    for _ in range(100_000):
        var g = game.copy()
        root._expand(g)
    var pv = List[Game.Move]()
    root._pv(pv)
    print(len(pv), pv)
    print(repr(root))
