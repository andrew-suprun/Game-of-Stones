from testing import assert_true

from game import Score, Move
from game_of_stones.gomoku import Gomoku, max_stones, values

fn test_play_move() raises:
    var gomoku = Gomoku[19, 10]()
    gomoku.play_move(Move("j10"))
    print(gomoku)
    print(gomoku.board.str_scores())
    assert_true(False)

