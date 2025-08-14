from game_of_stones import game_of_stones
from score import draw
from gomoku import Gomoku
from negamax import Negamax

alias Game = Gomoku[max_places=15]
alias Tree = Negamax[Game, max_moves=32, no_legal_moves_decision=draw]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Gomoku-Negamax", Tree, Game, stones_per_move=1]()
