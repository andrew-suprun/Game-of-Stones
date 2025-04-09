from game import Game, Move, Score, is_win
from tree import Tree, Node
from game_of_stones import Connect6

from random import seed, random_si64, random_float64
import testing

alias C6 = Connect6[19, 20, 10]

def test_tree():
    var g = C6()
    var t = Tree[C6, 30]()
    g.play_move(Move("j10"))
    g.play_move(Move("i9-i10"))

    print(g)
    var done = t.expand(g)
    print(done, t.value())
    print(t)
    testing.assert_true(done and is_win(t.value()))
