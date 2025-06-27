from game_of_stones import game_of_stones
from connect6 import Connect6

fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6", Connect6[size = 19, max_moves = 20, max_places = 20], c = 30, stones_per_move = 2]()
