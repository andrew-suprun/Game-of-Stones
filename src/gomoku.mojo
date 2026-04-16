from traits import TGame, TMove, MoveScore, Score
from board import Board, Place, PlaceScore, first

comptime win_stones = 5
comptime values: List[Score] = [0, 1, 5, 25, 125, 1250]


struct Move(TMove):
    var _place: Place
    var _decisive: Bool

    def __init__(out self):
        self = Self(Place(), False)

    def __init__(out self, place: Place, terminal: Bool = False):
        self._place = place
        self._decisive = terminal

    @implicit
    def __init__(out self, move: String) raises:
        self._place = Place(String(move))
        self._decisive = False

    def __eq__(self: Self, other: Self) -> Bool:
        return self._place == other._place and self._decisive == other._decisive

    def is_decisive(self) -> Bool:
        return self._decisive

    def set_decisive(mut self):
        self._decisive = True

    def write_to[W: Writer](self, mut writer: W):
        if self._decisive:
            writer.write("[", self._place, "]")
        else:
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

    def moves(self) -> List[MoveScore[Move]]:
        var moves = List[MoveScore[Move]](capacity=Self.max_places)
        self._moves(moves)
        if self.plies == Self.max_plies:
            var last_move = moves[len(moves)-1]
            last_move.move._decisive = True
            return [last_move]
        return moves^

    def _moves(self, mut moves: List[MoveScore[Move]]):
        var places = List[PlaceScore](capacity=Self.max_places)
        self.board.places(self.turn, places)
        var board_score = self.board._score if self.turn == first else -self.board._score
        for place in places:
            var score = place.score
            if score > 1000:
                moves.clear()
                moves.append({{place.place, True}, score})
                return
            moves.append({{place.place}, board_score + score / 2})

    def play_move(mut self, move: Move):
        self.board.place_stone(move._place, self.turn)
        self.turn = 1 - self.turn
        self.plies += 1

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
