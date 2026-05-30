from std.utils.numerics import FPUtils, isinf

from .traits import TGame, TMove, Score, MoveScore
from .board import Board, Place, PlaceValue, first

comptime win_stones = 5
comptime values: List[Value] = [0, 1, 16, 256, 4096]


struct Move(TMove):
    var _place: Place

    def __init__(out self):
        self._place = Place()

    def __init__(out self, place: Place):
        self._place = place

    @implicit
    def __init__(out self, move: String) raises:
        self._place = Place(String(move))

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self._place)


struct Gomoku2[size: Int, max_moves: Int](TGame):
    comptime Move = Move
    comptime Score = Score

    var board: Board[Self.size, values, win_stones]
    var turn: Int
    var plies: Int

    def __init__(out self):
        self.board = Board[Self.size, values, win_stones]()
        self.turn = 0
        self.plies = 0

    def top_moves(self) -> List[MoveScore[Move]]:
        var moves = List[MoveScore[Move]](capacity=Self.max_moves)
        self._moves(moves)
        return moves^

    def _moves(self, mut moves: List[MoveScore[Move]]):
        var places = List[PlaceValue](capacity=Self.max_moves)
        self.board.places(self.turn, places)
        var board_value = self.board.value if self.turn == first else -self.board.value
        for place in places:
            if place.value == Value.MAX:
                moves.clear()
                moves.append({{place.place}, Score.win()})
                return
            var value = board_value + place.value / 2
            moves.append({{place.place}, Score(value)})

        if not moves:
            moves.append({{places[0].place}, Score(Loss)})

    def play_move(mut self, move: Move):
        self.board.place_stone(move._place, self.turn)
        self.turn = 1 - self.turn
        self.plies += 1

    def score(self) -> Score:
        return Score(self.board.value)

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
