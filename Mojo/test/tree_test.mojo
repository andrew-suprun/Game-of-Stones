from tree import Game, Move, Score, is_win
from tree.tree import Tree, Node
from game_of_stones import Gomoku

from random import seed, random_si64, random_float64
import testing

alias G = Gomoku[19, 32]

def test_tree():
    var g = G()
    var t = Tree[G, 20]()
    g.play_move(Move("j10"))
    g.play_move(Move("a1"))
    g.play_move(Move("j9"))
    g.play_move(Move("a2"))
    g.play_move(Move("j11"))
    g.play_move(Move("a3"))

    print(g)
    for i in range(2):
        _ = t.expand(g)
        print(i, t)
    print(t.value())
    testing.assert_true(is_win(t.value()))
