from sys import env_get_int

from engine import run
from connect6 import Connect6

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 32]()
alias max_places = env_get_int["MAX_PLACES", 16]()
alias exp_factor = env_get_int["EXP_FACTOR", 32]()

fn main() raises:
    run[Connect6[board_size, max_moves, max_places], exp_factor]()
