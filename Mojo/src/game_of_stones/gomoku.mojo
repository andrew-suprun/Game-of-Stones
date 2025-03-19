from sys import env_get_int
from collections import InlineArray

from tree import Game, Move, MoveScore, Score, win, draw

from .heap import add
from .board import Board, Place, first, second

alias max_stones = 5

alias values = List[Score](Score(0), Score(1), Score(5), Score(25), Score(125), win)


struct Gomoku[size: Int, max_moves: Int](Game):
    var board: Board[values, size, max_stones, max_moves]
    var turn: Int
    var top_places: List[Place]
    var history: List[Move]

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_moves]()
        self.turn = 0
        self.top_places = List[Place]()
        self.history = List[Move]()

    fn name(self, out name: String):
        name = "gomoku"

    fn top_moves(mut self, mut move_scores: List[MoveScore]):
        @parameter
        fn less(a: MoveScore, b: MoveScore, out r: Bool):
            r = a.score < b.score

        move_scores.clear()
        self.board.top_places(self.turn, self.top_places)

        if not self.top_places:
            move_scores.append(MoveScore(Move(0, 0, 0, 0), draw))
            return

        var has_draw = False

        for p in self.top_places:
            var place = p[]
            var score = self.board.getscores(place)[self.turn]

            if score == win:
                move_scores.clear()
                move_scores.append(MoveScore(Move(place, place), win))
                return
            elif score == 0:
                if not has_draw:
                    add[MoveScore, max_moves, less](MoveScore(Move(place, place), draw), move_scores)
                    has_draw = True
            else:
                var coeff = 1 - 2 * self.turn
                var move_score = self.board.getscores(place)[self.turn] // 2 + coeff * self.board.score
                add[MoveScore, max_moves, less](MoveScore(Move(place, place), move_score), move_scores)

    fn play_move(mut self, move: Move):
        self.history.append(move)

        self.board.place_stone(move.p1, self.turn)
        self.turn = 1 - self.turn

    fn undo_move(mut self):
        if len(self.history) == 0:
            return

        self.turn = 1 - self.turn
        self.history.resize(len(self.history)-1)
        self.board.remove_stone()

    fn decision(self, out decision: String):
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)

alias board_size = env_get_int["BOARD_SIZE", 19]()
alias max_moves = env_get_int["MAX_MOVES", 32]()
alias exp_factor = env_get_int["EXP_FACTOR", 20]()


