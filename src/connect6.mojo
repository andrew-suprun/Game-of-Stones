from utils.numerics import inf, isinf

from score import Score, win, draw, is_win, is_decisive, less
from game import TGame, TMove
from heap import heap_add
from board import Board, Place

alias max_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625)

@register_passable("trivial")
struct Move(TMove):
    var p1: Place
    var p2: Place
    var _score: Score

    fn __init__(out self):
        self = Self.__init__(Place(0, 0), Place(0, 0), 0)

    fn __init__(out self, p1: Place = Place(0, 0), p2: Place = Place(0, 0), score: Score = 0):
        self.p1 = p1
        self.p2 = p2
        self._score = 0

    fn __init__(out self, move: String) raises:
        var tokens = move.split("-")
        self.p1 = Place(tokens[0])
        if len(tokens) == 2:
            self.p2 = Place(tokens[1])
        else:
            self.p2 = self.p1
        self._score = 0

    @always_inline
    fn score(self) -> Score:
        return self._score


    @always_inline
    fn set_score(mut self, score: Score):
        self._score = score

    @always_inline
    fn is_decisive(self) -> Bool:
        return is_decisive(self._score)

    fn __str__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self.p1 != self.p2:
            writer.write(self.p1, "-", self.p2)
        else:
            writer.write(self.p1)

struct Connect6[size: Int, max_moves: Int, max_places: Int](TGame):
    alias Move = Move
    var board: Board[values, size, max_stones, max_places]
    var turn: Int
    var top_places: List[Place]
    var history: List[Self.Move]

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_places]()
        self.turn = 0
        self.top_places = List[Place]()
        self.history = List[Self.Move]()

    fn name(self, out name: String):
        name = "connect6"

    fn moves(mut self, mut move_scores: List[self.Move]):
        @parameter
        fn move_less(a: self.Move, b: self.Move, out r: Bool):
            r = less(a.score(), b.score())

        move_scores.clear()
        self.board.top_places(self.turn, self.top_places)

        if len(self.top_places) < 2:
            move_scores.append(Move(score = draw))
            return

        for i in range(len(self.top_places) - 1):
            var place1 = self.top_places[i]
            var score1 = self.board.getscores(place1)[self.turn]
            if is_win(score1):
                move_scores.clear()
                move_scores.append(Move(place1, place1, win))
                return

            self.board.place_stone(place1, self.turn)

            for j in range(i + 1, len(self.top_places)):
                var place2 = self.top_places[j]
                var score2 = self.board.getscores(place2)[self.turn]

                if isinf(score2) and score2 > 0:
                    move_scores.clear()
                    move_scores.append(Move(place1, place2, win))
                    return
                var score = -self.board.score + score1 + score2 if score1 + score2 == 0 else draw
                heap_add[Move, max_moves, move_less](Move(place1, place2, score), move_scores)


    fn play_move(mut self, move: self.Move):
        self.history.append(move)
        self.board.place_stone(move.p1, self.turn)
        if move.p1 != move.p2:
            self.board.place_stone(move.p2, self.turn)
        self.turn = 1 - self.turn

    fn decision(self, out decision: String):
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
