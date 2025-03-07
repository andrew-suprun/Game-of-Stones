from heap import add
from scores import Score, win, draw
import values as v
from board import Board, Place, first, second
from game import Game, Move, MoveScore
from engine import run

alias max_stones = 5

alias values = List[Score](Score(0), Score(1), Score(5), Score(25), Score(125), win)

alias value_table = v.value_table[max_stones, values]()

struct Gomoku[size: Int, max_moves: Int](Game):
    var board: Board[size, max_stones, max_moves]
    var top_places: List[Place]
    var history: List[Move]

    fn __init__(out self):
        self.board = Board[size, max_stones, max_moves]()
        self.top_places = List[Place]()
        self.history = List[Move]()

    fn name(self, out name: String):
        name = "gomoku"

    fn top_moves(mut self, mut move_scores: List[MoveScore]):
        @parameter
        fn less(a: MoveScore, b: MoveScore, out r: Bool):
            r = a.score < b.score

        var turn_first = self.board.turn == first
        move_scores.clear()
        self.board.top_places(self.top_places)

        if not self.top_places:
            move_scores.append(MoveScore(Move(0, 0, 0, 0), draw))
            return

        var has_draw = False

        for p in self.top_places:
            var place = p[]
            var score = self.board.getscores(place)[0] + self.board.getscores(place)[1]

            if self.board.score == win:
                move_scores.append(MoveScore(Move(place, place), win))
                return
            elif score == 0:
                if not has_draw:
                    add[MoveScore, max_moves, less](MoveScore(Move(place, place), draw), move_scores)
                    has_draw = True
            else:
                var move_score = (self.board.getscores(place)[first] + self.board.score) // 2  if turn_first
                    else (self.board.getscores(place)[second] - self.board.score) // 2

                add[MoveScore, max_moves, less](
                    MoveScore(Move(place, place), move_score),
                    move_scores,
                )

    fn play_move(mut self, move: Move):
        self.history.append(move)
        if self.board.turn == board.first:
            self.board.place_stone(move.p1, value_table[board.first])
            self.board.setturn(board.second)
        else:
            self.board.place_stone(move.p1, value_table[board.second])
            self.board.setturn(board.first)

    fn undo_move(mut self):
        if self.board.turn == board.first:
            self.board.setturn(board.second)
        else:
            self.board.setturn(board.first)
        self.history.resize(len(self.history)-1)
        self.board.remove_stone()

def main():
    run[Gomoku[19, 32]](20)

