from .config import Assert, Trace
from .traits import TGame, TMove, MoveScore
from .board import Board, Value, Place, PlaceValue, first
from .heap import heap_add

comptime win_stones = 6
comptime values: List[Value] = [0, 1, 5, 25, 125, 625]


struct Move(TMove):
    var _p1: Place
    var _p2: Place

    def __init__(out self):
        self._p1 = Place()
        self._p2 = Place()

    def __init__(out self, p1: Place, p2: Place):
        if p1 < p2:
            self._p1 = p1
            self._p2 = p2
        else:
            self._p1 = p2
            self._p2 = p1

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

    def write_to[W: Writer](self, mut writer: W):
        if self._p1 != self._p2:
            writer.write(self._p1, "-", self._p2)
        else:
            writer.write(self._p1)


def lt(a: MoveScore[Move], b: MoveScore[Move]) -> Bool:
    return a.score < b.score


struct Connect6[size: Int, max_moves: Int, max_places: Int](TGame):
    comptime Move = Move

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
        var places = List[PlaceValue](capacity=Self.max_places)
        self.board.places(self.turn, places)
        if len(places) <= 1:
            print(self)
        assert len(places) > 1

        var board_value = self.board.value if self.turn == first else -self.board.value
        for i in range(len(places) - 1):
            var place1 = places[i].place
            var score1 = places[i].value
            if score1 == Value.MAX:
                moves.clear()
                moves.append({{place1, place1}, Score.win()})
                return

            var board = self.board.copy()
            board.place_stone(place1, self.turn)

            for j in range(i + 1, len(places)):
                var place2 = places[j].place
                var score2 = board.get_value(place2, self.turn)

                if score2 == Value.MAX:
                    moves.clear()
                    moves.append({{place1, place2}, Score.win()})
                    return

                var board2 = board.copy()
                board2.place_stone(place2, self.turn)

                comptime if Assert:
                    var debug_board_value = board2.debug_board_value(materialize[values]())
                    if self.turn:
                        debug_board_value = -debug_board_value
                    comptime if Assert:
                        if not Score(board_value).is_decisive() and debug_board_value != board_value + score1 + score2:
                            print(self.board)
                            print(self.board.str_values())
                            print("move", Move(place1, place2))
                            print(t"debug_board_value={debug_board_value}, board_value={board_value}, score1={score1}, score2={score2}")
                            assert False

                var max_opp_value = board2.max_value(1 - self.turn)
                if max_opp_value != Value.MAX:
                    var move_value = board_value + score1 + score2 - max_opp_value
                    heap_add[lt]({{place1, place2}, Score(move_value)}, moves)

        if not moves:
            moves.append({{places[0].place, places[1].place}, Score.loss()})

    def play_move(mut self, move: Move):
        self.board.place_stone(move._p1, self.turn)
        if move._p1 != move._p2:
            self.board.place_stone(move._p2, self.turn)
        self.turn = 1 - self.turn
        self.plies += 1

    def score(self) -> Score:
        return Score(self.board.value)

    def write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
