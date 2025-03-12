from sys import env_get_int
from collections import InlineArray

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



struct Connect6[size: Int, max_moves: Int, max_places: Int](Game):
    var board: Board[size, max_stones, max_places]
    var top_places: List[Place]
    var history: List[Move]
    var value_table: InlineArray[List[SIMD[DType.float32, 2]], 2]

    fn __init__(out self):
        self.board = Board[size, max_stones, max_places]()
        self.top_places = List[Place]()
        self.history = List[Move]()
        self.value_table = v.value_table[max_stones, values]()

    fn name(self, out name: String):
        name = "connect6"

    fn top_moves(mut self, mut move_scores: List[MoveScore]):
        @parameter
        fn less(a: MoveScore, b: MoveScore, out r: Bool):
            r = a.score < b.score

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

            self.board.place_stone(place1, self.value_table[self.board.turn])

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
                    self.board.place_stone(place2, self.value_table[self.board.turn])
                    var opp_turn = 1 - self.board.turn
                    var coeff = 1 - 2 * self.board.turn
                    var opp_score = self.board.max_score(opp_turn)
                    var move_score = coeff * self.board.score - opp_score
                    self.board.remove_stone()

                    add[MoveScore, max_moves, less](
                        MoveScore(Move(place1, place2), move_score),
                        move_scores,
                    )

            self.board.remove_stone()

    fn play_move(mut self, move: Move):
        self.history.append(move)

        self.board.place_stone(move.p1, self.value_table[self.board.turn])
        if move.p1 != move.p2:
            self.board.place_stone(move.p2, self.value_table[self.board.turn])
        self.board.turn = 1 - self.board.turn

    fn undo_move(mut self):
        if len(self.history) == 0:
            return

        self.board.turn = 1 - self.board.turn

        var move = self.history[-1]
        self.history.resize(len(self.history)-1)
        if move.p1 != move.p2:
            self.board.remove_stone()
        self.board.remove_stone()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 60]()
alias max_places = env_get_int["MAX_PLACES", 32]()
alias exp_factor = env_get_int["EXP_FACTOR", 20]()

fn main() raises:
    run[Connect6[board_size, max_moves, max_places]](Score(exp_factor))
