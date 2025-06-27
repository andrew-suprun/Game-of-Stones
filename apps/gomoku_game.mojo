from game_of_stones import game_of_stones
from gomoku import Gomoku

fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Gomoku", Gomoku[size = 19, max_moves = 20], c = 30, stones_per_move = 1]()
