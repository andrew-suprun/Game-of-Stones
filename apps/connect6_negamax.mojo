from game_of_stones import game_of_stones
from connect6 import Connect6
from negamax_zero import NegamaxZero

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
alias Tree = NegamaxZero[Game]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6-Negamax", Tree, Game, stones_per_move=2]()
