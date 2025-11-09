from game_of_stones import game_of_stones
from gomoku import Gomoku
from negamax import Negamax
from negamax.principal_variation_memory import PrincipalVariationMemory

alias Game = Gomoku[size=19, max_places=15, max_plies=100]
alias Tree = Negamax[PrincipalVariationMemory[Game]]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Gomoku-PVS-Negamax", Tree, Game, stones_per_move=1]()
