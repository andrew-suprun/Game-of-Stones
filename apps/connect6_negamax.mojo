from game_of_stones import game_of_stones
from connect6 import Connect6
from negamax import Negamax

alias Game = Connect6[max_moves=20, max_places=15, max_plies=100]
alias Tree = Negamax[Game]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6-Negamax", Tree, Game, stones_per_move=2]()
