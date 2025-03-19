from sys import env_get_int

from engine import run
from game_of_stones import Connect6

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 60]()
alias max_places = env_get_int["MAX_PLACES", 32]()
alias exp_factor = env_get_int["EXP_FACTOR", 20]()

fn main() raises:
    run[Connect6[board_size, max_moves, max_places], exp_factor]()
