from sys import env_get_int

from game_of_stones import game_of_stones
from connect6 import Connect6

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 32]()
alias max_places = env_get_int["MAX_PLACES", 20]()
alias exp_factor = env_get_int["EXP_FACTOR", 200]()

fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6", Connect6[board_size, max_moves, max_places], exp_factor, stones_per_move = 2]()
