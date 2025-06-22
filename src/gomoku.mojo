from game import TGame, TMove

from score import Score, is_win, win, draw, is_decisive, less
from game import TGame, TMove
from heap import heap_add
from board import Board, Place

alias max_stones = 5
alias values = List[Float32](0, 1, 5, 25, 125)

@register_passable("trivial")
struct Move(TMove):
    var place: Place
    var _score: Score

    fn __init__(out self):
        self = Self.__init__(Place(0, 0), 0)

    fn __init__(out self, place: Place = Place(0, 0), score: Score = 0):
        self.place = place
        self._score = 0

    fn __init__(out self, move: String) raises:
        self.place = Place(move)
        self._score = 0

    fn score(self) -> Score:
        return self._score

    fn set_score(mut self, score: Score):
        self._score = score

    fn is_decisive(self) -> Bool:
        return is_decisive(self._score)

    fn __str__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.place)

struct Gomoku[size: Int, max_moves: Int](TGame):
    alias Move = Move

    var board: Board[values, size, max_stones, max_moves]
    var turn: Int
    var top_places: List[Place]

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_moves]()
        self.turn = 0
        self.top_places = List[Place]()

    fn name(self, out name: String):
        name = "gomoku"

    fn moves(mut self, mut move_scores: List[Move]):
        @parameter
        fn move_less(a: self.Move, b: self.Move, out r: Bool):
            r = less(a.score(), b.score())

        move_scores.clear()
        self.board.top_places(self.turn, self.top_places)

        if not self.top_places:
            move_scores.append(Move(score = draw))
            return

        var has_draw = False

        for place in self.top_places:
            var score = self.board.getscores(place)[self.turn]

            if is_win(score):
                move_scores.clear()
                move_scores.append(Move(place, win))
                return
            elif score == 0:
                if not has_draw:
                    heap_add[Move, max_moves, move_less](Move(place, draw), move_scores)
                    has_draw = True
            else:
                heap_add[Move, max_moves, move_less](Move(place, self.board.score + score), move_scores)

    fn play_move(mut self, move: self.Move):
        self.board.place_stone(move.place, self.turn)
        self.turn = 1 - self.turn

    fn decision(self, out decision: String):
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)

