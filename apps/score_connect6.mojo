from eval import run
from connect6 import Connect6, Move
from board import Place

comptime Game = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]


fn main() raises:
    var game = Game()
    _ = game.play_move(Move(Place(9, 9), Place(9, 9)))
    score = game.play_move(Move(Place(8, 9), Place(10, 8)))
    print(score)
    print(game)
    print(game.board.str_scores())
