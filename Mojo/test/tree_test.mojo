from tree import Game, Move, Score
from tree.impl import Tree, Node
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

    for _ in range(3):
        _ = t.expand(g)
    print(g)
    print(t)
