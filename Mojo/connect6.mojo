from utils.numerics import inf

from scores import Score, win, draw
from game import Game, Move, MoveScore
from board import Board, Place, first, second
import values as v
from heap import add

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


struct Connect6[size: Int, max_moves: Int, max_places: Int](Game):
    var board: Board[size, max_stones, max_places]
    var top_places: List[Place]

    fn __init__(out self):
        self.board = Board[size, max_stones, max_places]()
        self.top_places = List[Place]()

    fn top_moves(mut self, mut move_scores: List[MoveScore]):
        @parameter
        fn less(a: MoveScore, b: MoveScore, out r: Bool):
            r = a.score < b.score

        var turn_first = self.board.turn == first
        move_scores.clear()
        self.board.top_places(self.top_places)
        if len(self.top_places) < 2:
            move_scores.append(MoveScore(Move(0, 0, 0, 0), draw))
            return

        var has_draw = False

        # TODO use enumerated iterator
        for i in range(len(self.top_places)):
            var place1 = self.top_places[i]
            var scores = self.board.getscores(place1)
            var score1 = scores[0] if turn_first else scores[second]
            if score1 == win:
                move_scores.append(MoveScore(Move(place1, place1), win))
                return

            if turn_first:
                self.board.place_stone(place1, 1, value_table[0])
            else:
                self.board.place_stone(place1, 1, value_table[1])

            for j in range(i + 1, len(self.top_places)):
                var place2 = self.top_places[j]
                var scores = self.board.getscores(place2)
                var score2 = scores[0] if turn_first else scores[second]
                if score2 == win:
                    move_scores.append(MoveScore(Move(place1, place2), win))
                    return

                var score = score1 + score2
                if score == 0:
                    if not has_draw:
                        move_scores.append(
                            MoveScore(Move(place1, place2), draw)
                        )
                        has_draw = True
                else:
                    var opp_score = Score(0)
                    if turn_first:
                        self.board.place_stone(place2, 1, value_table[0])
                        opp_score = (
                            score
                            - self.board.max_score[second]()
                            - self.board.score
                        )
                        self.board.place_stone(place2, -1, value_table[0])
                    else:
                        self.board.place_stone(place2, 1, value_table[1])
                        opp_score = (
                            score
                            - self.board.max_score[first]()
                            - self.board.score
                        )
                        self.board.place_stone(place2, -1, value_table[1])

                    add[MoveScore, max_moves, less](
                        MoveScore(Move(place1, place2), opp_score), move_scores
                    )

            if turn_first:
                self.board.place_stone(place1, -1, value_table[0])
            else:
                self.board.place_stone(place1, -1, value_table[1])

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


fn main():
    pass
