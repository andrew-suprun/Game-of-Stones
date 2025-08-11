from sys import env_get_int

from game_of_stones import game_of_stones
from score import draw
from negamax import Negamax
from gomoku import Gomoku

alias Game = Gomoku[size = 19, max_places = 18]
alias Tree = Negamax[Game, max_moves = 32, no_legal_moves_decision = draw]

fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Gomoku-Negamax", Tree, Game, stones_per_move = 1]()
