from game_of_stones import GameOfStones
from gomoku import Gomoku

fn main() raises:
    var done = False
    while not done:
        var game = GameOfStones[Gomoku[size = 19, max_moves = 20], c = 30, max_selected = 1]("Gomoku")
        done = game.run()
