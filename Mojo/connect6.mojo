from utils.numerics import inf

from scores import Score
from game import Move
from board import Board
import values as v

alias max_stones = 6

alias values = List[Score](
    Score(0),
    Score(1),
    Score(5),
    Score(25),
    Score(125),
    Score(625),
    inf[DType.float32](),
)

alias value_table = v.value_table[max_stones, values]()


struct Connect6[size: Int]:
    var board: Board[size, max_stones]

    fn __init__(out self):
        self.board = Board[size, max_stones]()

    fn top_moves(self, mut moves: List[Move], mut values: List[Score]):
        ...

    fn play_move(mut self, move: Move):
        if self.board.turn == board.first:
            self.board.place_stone(move.p1, 1, value_table[board.first])
            if move.p1 != move.p2:
                self.board.place_stone(move.p2, 1, value_table[board.first])
            self.board.setturn(board.second)
        else:
            self.board.place_stone(move.p1, 1, value_table[board.second])
            if move.p1 != move.p2:
                self.board.place_stone(move.p2, 1, value_table[board.second])
            self.board.setturn(board.first)

    fn undo_move(mut self, move: Move):
        if self.board.turn == board.first:
            self.board.setturn(board.second)
            self.board.place_stone(move.p1, -1, value_table[board.first])
            if move.p1 != move.p2:
                self.board.place_stone(move.p2, -1, value_table[board.first])
        else:
            self.board.setturn(board.first)
            self.board.place_stone(move.p1, -1, value_table[board.second])
            if move.p1 != move.p2:
                self.board.place_stone(move.p2, -1, value_table[board.second])

    fn score(self, out score: Score):
        score = self.board.score
