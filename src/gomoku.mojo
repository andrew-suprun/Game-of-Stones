from std.utils.numerics import FPUtils, isinf

from value import Value, Win, Draw
from traits import TGame, TMove, MoveValue
from board import Board, Place, PlaceValue, first

comptime win_stones = 5
comptime values: List[Value] = [0, 1, 5, 25, 125]


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


struct Gomoku[size: Int, max_places: Int, max_plies: Int](TGame):
    comptime Move = Move

    var board: Board[Self.size, values, win_stones]
    var turn: Int
    var plies: Int

    def __init__(out self):
        self.board = Board[Self.size, values, win_stones]()
        self.turn = 0
        self.plies = 0

    def moves(self) -> List[MoveValue[Move]]:
        var moves = List[MoveValue[Move]](capacity=Self.max_places)
        self._moves(moves)
        if self.plies >= Self.max_plies:
            var last_move = moves[len(moves) - 1]
            last_move.value = Draw
            return [last_move]
        return moves^

    def _moves(self, mut moves: List[MoveValue[Move]]):
        var places = List[PlaceValue](capacity=Self.max_places)
        self.board.places(self.turn, places)
        var board_value = self.board.value if self.turn == first else -self.board.value
        for place in places:
            if place.value == Value.MAX:
                moves.clear()
                moves.append({{place.place}, Win})
                return
            var value = board_value + place.value / 2
            moves.append({{place.place}, Value(value)})

    def play_move(mut self, move: Move):
        self.board.place_stone(move._place, self.turn)
        self.turn = 1 - self.turn
        self.plies += 1

    def value(self) -> Value:
        return self.board.value

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
