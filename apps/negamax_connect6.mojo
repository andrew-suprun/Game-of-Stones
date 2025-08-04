from sys import env_get_int

from engine import run
from game import Score
from negamax import Negamax
from connect6 import Connect6

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 32]()
alias max_places = env_get_int["MAX_PLACES", 16]()
alias exp_factor = env_get_int["EXP_FACTOR", 32]()

fn main() raises:
    alias C6 = Connect6[board_size, max_places]
    alias Tree = Negamax[C6, max_moves]
    run[Tree](Score(0))
