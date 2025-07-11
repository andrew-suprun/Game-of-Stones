from sys import env_get_int

from game_of_stones import game_of_stones
from gomoku import Gomoku

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 16]()
alias exp_factor = env_get_int["EXP_FACTOR", 16]()


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Gomoku", Gomoku[board_size, max_moves], exp_factor, stones_per_move = 1]()
