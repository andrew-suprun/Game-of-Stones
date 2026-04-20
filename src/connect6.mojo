from std.sys.defines import get_defined_string

from traits import TGame, TMove, Score
from board import Board, Place, PlaceScore, first
from heap import heap_add

comptime assert_mode = get_defined_string["ASSERT", "none"]()
comptime win_stones = 6
comptime values: List[Score] = [0, 1, 5, 25, 125, 625, 6250]


struct Move(TMove):
    var _p1: Place
    var _p2: Place
    var _score: Score
    var _decisive: Bool

    def __init__(out self):
        self._p1 = Place()
        self._p2 = Place()
        self._score = Score.MIN
        self._decisive = False

    def __init__(out self, p1: Place, p2: Place, score: Score, terminal: Bool = False):
        if p1 < p2:
            self._p1 = p1
            self._p2 = p2
        else:
            self._p1 = p2
            self._p2 = p1
        self._score = score
        self._decisive = terminal

    @implicit
    def __init__(out self, move: String) raises:
        var tokens = move.split("-")
        var p1 = Place(String(tokens[0]))
        var p2: Place
        if len(tokens) == 2:
            p2 = Place(String(tokens[1]))
        else:
            p2 = p1
        if p1 < p2:
            self._p1 = p1
            self._p2 = p2
        else:
            self._p1 = p2
            self._p2 = p1
        self._score = Score.MIN
        self._decisive = False

    def __eq__(self: Self, other: Self) -> Bool:
        return self._p1 == other._p1 and self._p2 == other._p2

    def score(self) -> Score:
        return self._score

    def set_score(mut self, score: Score):
        self._score = score

    def is_decisive(self) -> Bool:
        return self._decisive

    def set_decisive(mut self):
        self._decisive = True

    def write_to[W: Writer](self, mut writer: W):
        if self._p1 != self._p2:
            writer.write(self._p1, "-", self._p2)
        else:
            writer.write(self._p1)

    def write_repr_to[W: Writer](self, mut writer: W):
        if self._decisive:
            writer.write("#")
        self.write_to(writer)
        writer.write(" ", self._score)


def less(a: Move, b: Move) -> Bool:
    return a.score() < b.score()


struct Connect6[size: Int, max_moves: Int, max_places: Int, max_plies: Int](TGame):
    comptime Move = Move
    comptime Win = 5000

    var board: Board[Self.size, values, win_stones]
    var turn: Int
    var plies: Int

    def __init__(out self):
        self.board = Board[Self.size, values, win_stones]()
        self.turn = 0
        self.plies = 0

    def moves(self) -> List[Move]:
        var moves = List[Move](capacity=Self.max_moves)
        self._moves(moves)
        if self.plies == Self.max_plies:
            var last_move = moves[len(moves) - 1]
            last_move._score = 0
            last_move._decisive = True
            return [last_move]
        return moves^

    def _moves(self, mut moves: List[Move]):
        var places = List[PlaceScore](capacity=Self.max_places)
        self.board.places(self.turn, places)
        if len(places) <= 1:
            print(self)
        assert len(places) > 1

        var board_score = self.board._score if self.turn == first else -self.board._score
        for i in range(len(places) - 1):
            var place1 = places[i].place
            var score1 = places[i].score
            if score1 >= Self.Win:
                moves.clear()
                moves.append({place1, place1, score1, terminal = True})
                return

            var board = self.board.copy()
            board.place_stone(place1, self.turn)

            for j in range(i + 1, len(places)):
                var place2 = places[j].place
                var score2 = board.score(place2, self.turn)

                if score2 >= Self.Win:
                    moves.clear()
                    moves.append({place1, place2, score2, terminal = True})
                    return

                var board2 = board.copy()
                board2.place_stone(place2, self.turn)

                comptime if assert_mode == "all":
                    var board_value = board2.board_value(materialize[values]())
                    if self.turn:
                        board_value = -board_value
                    assert board_value == board_score + score1 + score2

                var max_opp_score = board2.max_score(1 - self.turn)
                var move_score = board_score + score1 + score2 - max_opp_score
                if max_opp_score < Self.Win:
                    heap_add[less]({place1, place2, move_score}, moves)

        if not moves:
            moves.append({places[0].place, places[1].place, -Self.Win, terminal = True})

    def play_move(mut self, move: Move):
        self.board.place_stone(move._p1, self.turn)
        if move._p1 != move._p2:
            self.board.place_stone(move._p2, self.turn)
        self.turn = 1 - self.turn
        self.plies += 1

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
