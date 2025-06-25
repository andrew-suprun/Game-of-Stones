from sys import env_get_int

from engine import run
from gomoku import Gomoku
from game import Score

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 12]()
alias exp_factor = env_get_int["EXP_FACTOR", 24]()

fn main() raises:
    run[Gomoku[board_size, max_moves], Score(exp_factor)]()
