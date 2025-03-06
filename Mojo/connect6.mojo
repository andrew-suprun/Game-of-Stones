from heap import add
from scores import Score, win, draw
import values as v
from board import Board, Place, first, second
from game import Game, Move, MoveScore
from engine import run

alias max_stones = 6

alias values = List[Score](
    Score(0),
    Score(1),
    Score(5),
    Score(25),
    Score(125),
    Score(625),
    win,
)

alias value_table = v.value_table[max_stones, values]()


struct Connect6[size: Int, max_moves: Int, max_places: Int](Game):
    var board: Board[size, max_stones, max_places]
    var top_places: List[Place]
    var history: List[Move]

    fn __init__(out self):
        self.board = Board[size, max_stones, max_places]()
        self.top_places = List[Place]()
        self.history = List[Move]()

    fn name(self, out name: String):
        name = "connect6"

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
        for i in range(len(self.top_places) - 1):
            var place1 = self.top_places[i]
            var score1 = self.board.getscores(place1)[0] + self.board.getscores(
                place1
            )[1]
            if turn_first:
                self.board.place_stone(place1, value_table[0])
            else:
                self.board.place_stone(place1, value_table[1])

            for j in range(i + 1, len(self.top_places)):
                var place2 = self.top_places[j]
                var score2 = self.board.getscores(place2)[0] + self.board.getscores(place2)[1]

                if self.board.score == win:
                    move_scores.append(MoveScore(Move(place1, place2), win))
                    return
                elif score1 + score2 == 0:
                    if not has_draw:
                        add[MoveScore, max_moves, less](MoveScore(Move(place1, place2), draw), move_scores)
                        has_draw = True
                else:
                    var move_score = Score(0)
                    if turn_first:
                        self.board.place_stone(place2, value_table[0])
                        var opp_score = self.board.max_score[second]()
                        move_score = self.board.score - opp_score
                        self.board.remove_stone()
                    else:
                        self.board.place_stone(place2, value_table[1])
                        var opp_score = self.board.max_score[first]()
                        move_score = -self.board.score - opp_score
                        self.board.remove_stone()

                    add[MoveScore, max_moves, less](
                        MoveScore(Move(place1, place2), move_score),
                        move_scores,
                    )

            self.board.remove_stone()

    fn play_move(mut self, move: Move):
        self.history.append(move)
        if self.board.turn == board.first:
            self.board.place_stone(move.p1, value_table[board.first])
            if move.p1 != move.p2:
                self.board.place_stone(move.p2, value_table[board.first])
            self.board.setturn(board.second)
        else:
            self.board.place_stone(move.p1, value_table[board.second])
            if move.p1 != move.p2:
                self.board.place_stone(move.p2, value_table[board.second])
            self.board.setturn(board.first)

    fn undo_move(mut self):
        if self.board.turn == board.first:
            self.board.setturn(board.second)
        else:
            self.board.setturn(board.first)
        var move = self.history[-1]
        self.history.resize(len(self.history)-1)
        if move.p1 != move.p2:
            self.board.remove_stone()
        self.board.remove_stone()

def main():
    run[Connect6[19, 60, 32]](20)
