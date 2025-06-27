from game_of_stones import GameOfStones
from connect6 import Connect6

fn main() raises:
    var done = False
    while not done:
        var game = GameOfStones[Connect6[size = 19, max_moves = 20, max_places = 20], c = 30, max_selected = 1]("Gomoku")
        done = game.run()
