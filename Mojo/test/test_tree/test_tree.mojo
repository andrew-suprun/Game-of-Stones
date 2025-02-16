import game
from tree import *

from testing import *


struct Game(game.Game):
    alias Move = Int

    fn top_moves(self, mut moves: List[game.Move], mut values: List[Float32]):
        pass

    fn play_move(mut self, move: game.Move):
        pass


def test_tree():
    var g = Game()
