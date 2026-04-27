from std.utils.numerics import FPUtils, isinf
from std.sys.defines import get_defined_string

from score import Score, Win, Draw, is_decisive, score_str
from traits import TGame, TMove
from board import Board, Place, PlaceScore, first

comptime assert_mode = get_defined_string["ASSERT", "none"]()
comptime win_stones = 5
comptime values: List[Score] = [0, 1, 5, 25, 125, Win]


struct Move(TMove):
    var _place: Place
    var _score: Score

    def __init__(out self):
        self._place = Place()
        self._score = 0

    def __init__(out self, place: Place, score: Score):
        self._place = place
        self._score = score

    @implicit
    def __init__(out self, move: String) raises:
        self._place = Place(String(move))
        self._score = 0

    def score(self) -> Score:
        return self._score

    def set_score(mut self, score: Score):
        self._score = score

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self._place)

    def write_repr_to[W: Writer](self, mut writer: W):
        self.write_to(writer)
        if is_decisive(self._score):
            writer.write("#")
        writer.write(" ", score_str(self._score))


struct Gomoku[size: Int, max_places: Int, max_plies: Int](TGame):
    comptime Move = Move

    var board: Board[Self.size, values, win_stones]
    var turn: Int
    var plies: Int

    def __init__(out self):
        self.board = Board[Self.size, values, win_stones]()
        self.turn = 0
        self.plies = 0

    def moves(self) -> List[Move]:
        var moves = List[Move](capacity=Self.max_places)
        self._moves(moves)
        if self.plies == Self.max_plies:
            var last_move = moves[len(moves) - 1]
            last_move._score = Draw
            return [last_move]
        return moves^

    def _moves(self, mut moves: List[Move]):
        var places = List[PlaceScore](capacity=Self.max_places)
        self.board.places(self.turn, places)
        var board_score = self.board._score if self.turn == first else -self.board._score
        for place in places:
            if place.score == Win:
                moves.clear()
                moves.append({place.place, Win})
                return
            var score = board_score + place.score / 2
            moves.append({place.place, score})

    def play_move(mut self, move: Move):
        self.board.place_stone(move._place, self.turn)
        self.turn = 1 - self.turn
        self.plies += 1

    def score(mut self) -> Score:
        return self.board.score()

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
