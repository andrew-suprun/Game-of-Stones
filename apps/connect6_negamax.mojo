from sys import env_get_int

from game_of_stones import game_of_stones
from game import draw
from negamax import Negamax
from connect6 import Connect6

alias Game = Connect6[size = 19, max_places = 15]
alias Tree = Negamax[Game, max_moves = 20, no_legal_moves_decision = draw]

fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6-Negamax", Tree, Game, stones_per_move = 2]()
