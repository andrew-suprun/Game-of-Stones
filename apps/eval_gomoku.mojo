from utils.numerics import inf
from game import Score
from gomoku import Gomoku
from negamax import Negamax

fn main() raises:
    alias Game = Gomoku[19, 15]
    alias Tree = Negamax[Game, 20]

    var moves_str: String = "j10 h10 i8 j8 l10 i9 " "k7 g11 f12 g10 k10 m10 l11"
    var moves = moves_str.split(" ")
    var game = Tree.Game()
    var tree = Tree(Score(0))

    for move_str in moves:
        var move = Tree.Game.Move(move_str)
        game.play_move(move)
    
    var (score, pv) = tree.search(game, 250)
    print(score, "ev:", end="")
    for move in pv:
        print("", move, end="")
    print()

