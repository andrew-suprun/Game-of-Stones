from sys import env_get_int

from heap import add
from scores import Score, win, draw
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
    var board: Board[values, size, max_stones, max_places]
    var turn: Int
    var top_places: List[Place]
    var history: List[Move]

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_places]()
        self.turn = 0
        self.top_places = List[Place]()
        self.history = List[Move]()

    fn name(self, out name: String):
        name = "connect6"

    fn top_moves(mut self, mut move_scores: List[MoveScore]):
        @parameter
        fn less(a: MoveScore, b: MoveScore, out r: Bool):
            r = a.score < b.score

        move_scores.clear()
        self.board.top_places(self.turn, self.top_places)

        if len(self.top_places) < 2:
            move_scores.append(MoveScore(Move(0, 0, 0, 0), draw))
            return

        for i in range(len(self.top_places) - 1):
            var place1 = self.top_places[i]
            var score1 = self.board.getscores(place1)[self.turn]
            if score1 == win:
                move_scores.clear()
                move_scores.append(MoveScore(Move(place1, place1), win))
                return

            self.board.place_stone(place1, self.turn)

            for j in range(i + 1, len(self.top_places)):
                var place2 = self.top_places[j]
                var score2 = self.board.getscores(place2)[self.turn]

                if score2 == win:
                    move_scores.clear()
                    move_scores.append(MoveScore(Move(place1, place2), win))
                    self.board.remove_stone()
                    return
                elif score1 + score2 == 0:
                    add[MoveScore, max_moves, less](MoveScore(Move(place1, place2), draw), move_scores)
                else:
                    self.board.place_stone(place2, self.turn)
                    var opp_turn = 1 - self.turn
                    var coeff = 1 - 2 * self.turn
                    var opp_score = self.board.max_score(opp_turn)
                    var move_score = coeff * self.board.score - opp_score
                    self.board.remove_stone()
                    add[MoveScore, max_moves, less](MoveScore(Move(place1, place2), move_score), move_scores)

            self.board.remove_stone()

    fn play_move(mut self, move: Move):
        self.history.append(move)

        self.board.place_stone(move.p1, self.turn)
        if move.p1 != move.p2:
            self.board.place_stone(move.p2, self.turn)
        self.turn = 1 - self.turn

    fn undo_move(mut self):
        if len(self.history) == 0:
            return

        self.turn = 1 - self.turn

        var move = self.history[-1]
        self.history.resize(len(self.history)-1)
        if move.p1 != move.p2:
            self.board.remove_stone()
        self.board.remove_stone()

    fn decision(self, out decision: String):
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 60]()
alias max_places = env_get_int["MAX_PLACES", 32]()
alias exp_factor = env_get_int["EXP_FACTOR", 20]()

fn main() raises:
    run[Connect6[board_size, max_moves, max_places], exp_factor]()
