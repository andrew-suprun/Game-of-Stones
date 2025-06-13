from game import Game, Move, Score, is_win
from tree import Tree, Node
from game_of_stones import Connect6, Gomoku

from random import seed, random_si64, random_float64
import testing

alias C6 = Connect6[19, 20, 10]

def test_connect6():
    var g = C6()
    var t = Tree[C6, 30]()
    g.play_move(Move("j10"))
    g.play_move(Move("i9-i10"))

    print(g)
    print(g.board.str_scores())
    for _ in range(1000):
        _ = t.expand(g)
    print("r =", t.value())
    testing.assert_true(t.value() == -2)

alias G = Gomoku[19, 10]

def test_gomoku():
    var g = G()
    var t = Tree[G, 30]()
    g.play_move(Move("j10"))
    g.play_move(Move("i9"))

    print(g)
    print(g.board.str_scores())
    for _ in range(1000):
        _ = t.expand(g)
    print("r =", t.value())
    testing.assert_true(t.value() == 24)
