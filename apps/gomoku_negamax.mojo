from game_of_stones import game_of_stones
from gomoku import Gomoku
from negamax import Negamax

alias Game = Gomoku[max_places=15, max_plies=100]
alias Tree = Negamax[Game]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Gomoku-Negamax", Tree, Game, stones_per_move=1]()
