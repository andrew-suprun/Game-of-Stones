from traits import TGame, TMove, Score
from board import Board, Place, PlaceScore, first

comptime win_stones = 5
comptime values: List[Score] = [0, 1, 5, 25, 125, 1250]


struct Move(TMove):
    var _place: Place
    var _score: Score
    var _decisive: Bool

    def __init__(out self):
        self._place = Place()
        self._score = Score.MIN
        self._decisive = False

    def __init__(out self, place: Place, score: Score, terminal: Bool = False):
        self._place = place
        self._score = score
        self._decisive = terminal


    @implicit
    def __init__(out self, move: String) raises:
        self._place = Place(String(move))
        self._score = Score.MIN
        self._decisive = False

    def __eq__(self: Self, other: Self) -> Bool:
        return self._place == other._place and self._decisive == other._decisive

    def score(self) -> Score:
        return self._score

    def set_score(mut self, score: Score):
        self._score = score

    def is_decisive(self) -> Bool:
        return self._decisive

    def set_decisive(mut self):
        self._decisive = True

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self._place)

    def write_repr_to[W: Writer](self, mut writer: W):
        if self._decisive:
            writer.write("#")
        self.write_to(writer)
        writer.write(" ", self._score)



struct Gomoku[size: Int, max_places: Int, max_plies: Int](TGame):
    comptime Move = Move
    comptime Win = 1000

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
            var last_move = moves[len(moves)-1]
            last_move._decisive = True
            last_move._score = 0
            return [last_move]
        return moves^

    def _moves(self, mut moves: List[Move]):
        var places = List[PlaceScore](capacity=Self.max_places)
        self.board.places(self.turn, places)
        var board_score = self.board._score if self.turn == first else -self.board._score
        for place in places:
            if place.score >= Self.Win:
                moves.clear()
                moves.append({place.place, place.score, terminal=True})
                return
            var score = board_score + place.score / 2
            assert score < Self.Win
            moves.append({place.place, score})

    def play_move(mut self, move: Move):
        self.board.place_stone(move._place, self.turn)
        self.turn = 1 - self.turn
        self.plies += 1

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
