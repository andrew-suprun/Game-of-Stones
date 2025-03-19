from sys import env_get_int

from engine import run
from game_of_stones.gomoku import Gomoku

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 60]()
alias exp_factor = env_get_int["EXP_FACTOR", 20]()

fn main() raises:
    run[Gomoku[board_size, max_moves], exp_factor]()
