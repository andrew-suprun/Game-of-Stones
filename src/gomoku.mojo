from std.utils.numerics import FPUtils, isinf

from traits import TGame, TMove, Score
from board import Board, Place, PlaceScore, first

comptime win_stones = 5
comptime _scores: List[Score] = [0, 1, 5, 25, 125, 1250]


struct Move(TMove):
    var _place: Place
    var _score: Score

    def __init__(out self):
        self._place = Place()
        self._score = Score.MIN

    def __init__(out self, place: Place, score: Score):
        self._place = place
        self._score = score

    @implicit
    def __init__(out self, move: String) raises:
        self._place = Place(String(move))
        self._score = Score.MIN

    def __eq__(self: Self, other: Self) -> Bool:
        return self._score == other._score

    def __lt__(self: Self, other: Self) -> Bool:
        return self._score < other._score

    def score(self) -> Score:
        return self._score

    def set_score(mut self, score: Score):
        self._score = score

    def is_win(self) -> Bool:
        return isinf(self._score) and self._score > 0

    def is_loss(self) -> Bool:
        return isinf(self._score) and self._score < 0

    def is_draw(self) -> Bool:
        return self._score == 0 and FPUtils.get_sign(self._score)

    def set_draw(mut self):
        self._score = -0.0

    def is_decisive(self) -> Bool:
        return isinf(self._score) or self.is_draw()

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self._place)

    def write_repr_to[W: Writer](self, mut writer: W):
        if self.is_decisive():
            writer.write("#")
        self.write_to(writer)
        writer.write(" ", self._score)


struct Gomoku[size: Int, max_places: Int, max_plies: Int](TGame):
    comptime Move = Move

    var board: Board[Self.size, _scores, win_stones]
    var turn: Int
    var plies: Int

    def __init__(out self):
        self.board = Board[Self.size, _scores, win_stones]()
        self.turn = 0
        self.plies = 0

    def moves(self) -> List[Move]:
        var moves = List[Move](capacity=Self.max_places)
        self._moves(moves)
        if self.plies == Self.max_plies:
            var last_move = moves[len(moves) - 1]
            last_move.set_draw()
            return [last_move]
        return moves^

    def _moves(self, mut moves: List[Move]):
        var places = List[PlaceScore](capacity=Self.max_places)
        self.board.places(self.turn, places)
        var board_score = self.board._score if self.turn == first else -self.board._score
        for place in places:
            if place.score == Score.MAX:
                moves.clear()
                moves.append({place.place, Score.MAX})
                return
            var score = board_score + place.score / 2
            moves.append({place.place, score})

    def play_move(mut self, move: Move):
        self.board.place_stone(move._place, self.turn)
        self.turn = 1 - self.turn
        self.plies += 1

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
