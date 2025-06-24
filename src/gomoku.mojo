from score import Score
from game import TGame, TMove
from heap import heap_add
from board import Board, Place, first

alias max_stones = 5
alias values = List[Score](0, 1, 5, 25, 125)

@register_passable("trivial")
struct Move(TMove):
    alias Score = Score

    var _place: Place
    var _score: Score

    fn __init__(out self):
        self = Self.__init__(Place(), 0)

    fn __init__(out self, place: Place = Place(0, 0), score: Score = 0):
        self._place = place
        self._score = score

    @implicit
    fn __init__(out self, move: String) raises:
        self._place = Place(move)
        self._score = 0

    @implicit
    fn __init__(out self, move: StringLiteral) raises:
        self._place = Place(move)
        self._score = 0

    fn score(self) -> Self.Score:
        return self._score

    fn set_score(mut self, score: Self.Score):
        self._score = score

    fn __eq__(self, other: Move) -> Bool:
        return self._place == other._place

    fn __ne__(self, other: Move) -> Bool:
        return self._place != other._place

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self._place)

struct Gomoku[size: Int, max_moves: Int](TGame, Writable):
    alias Move = Move

    var board: Board[values, size, max_stones, max_moves]
    var turn: Int

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_moves]()
        self.turn = first

    fn moves(self) -> List[Move]:
        @parameter
        fn move_less(a: self.Move, b: self.Move, out r: Bool):
            r = a.score() < b.score()

        var places = self.board.places(self.turn)
        if not places:
            return [Move(score = Score.draw())]

        var moves = List[Move](capacity = len(places))
        var board_score = self.board._score if self.turn == first else -self.board._score
        for place in places:
            moves.append(Move(place, board_score + self.board.getscore(place, self.turn)))
        return moves

    fn play_move(mut self, move: self.Move):
        self.board.place_stone(move._place, self.turn)
        self.turn = 1 - self.turn

    fn decision(self, out decision: String):
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
