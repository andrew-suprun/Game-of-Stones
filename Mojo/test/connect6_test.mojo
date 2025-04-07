from testing import assert_true

from game import Score, Move
from game_of_stones.connect6 import Connect6, max_stones, values

fn test_top_places() raises:
    var c6 = Connect6[19, 20, 10]()
    c6.play_move(Move(9, 9, 9, 9))
    print(c6)
    print(c6.board.str_scores())

