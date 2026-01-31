from sys import env_get_string
from hashlib.hasher import Hasher

from score import Score
from traits import TGame, TState, TMove, MoveScore
from board import Board, Place, first, value_table, Scores
from heap import heap_add

comptime debug = env_get_string["ASSERT_MODE", ""]()

comptime win_stones = 6
comptime values: List[Float32] = [0, 1, 5, 25, 125, 625]


struct Move(TMove):
    var _p1: Place
    var _p2: Place

    fn __init__(out self):
        self = Self(Place(), Place())

    fn __init__(out self, p1: Place, p2: Place):
        if p1 < p2:
            self._p1 = p1
            self._p2 = p2
        else:
            self._p1 = p2
            self._p2 = p1

    @implicit
    fn __init__(out self, move: String) raises:
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

    fn __eq__(self: Self, other: Self) -> Bool:
        return self._p1 == other._p1 and self._p2 == other._p2

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self._p1 != self._p2:
            writer.write(self._p1, "-", self._p2)
        else:
            writer.write(self._p1)


struct State[size: Int, win_stones: Int](TState):
    comptime Move = Move

    var board: Board[Self.size, Self.win_stones]
    var turn: Int
    var plies: Int

    fn __init__(out self):
        self.board = Board[Self.size, values, Self.win_stones]()
        self.turn = 0
        self.plies = 0

    fn __copyinit__(out self, existing: Self, /):
        self.board = existing.board.copy()
        self.turn = existing.turn
        self.plies = existing.plies

    fn __moveinit__(out self, deinit existing: Self):
        self.board = existing.board^
        self.turn = existing.turn
        self.plies = existing.plies


    fn moves(self, mut moves: List[MoveScore[Move]], values: List[List[Scores]]):
        @parameter
        fn less(a: MoveScore[Move], b: MoveScore[Move]) -> Bool:
            return a.score < b.score

        var places = List[Place](capacity=Self.max_places)
        self.board.places(self.turn, places)
        if len(places) <= 1:
            print(self)
        debug_assert(len(places) > 1)

        var board_score = self.board._score if self.turn == first else -self.board._score
        for i in range(len(places) - 1):
            var place1 = places[i]
            var score1 = self.board.score(place1, self.turn)
            if score1.is_win():
                moves.clear()
                moves.append(MoveScore(Move(place1, place1), score1))
                return

            var board = self.board.copy()
            board.place_stone(values, place1, self.turn)

            for j in range(i + 1, len(places)):
                var place2 = places[j]
                var score2 = board.score(place2, self.turn)

                if score2.is_win():
                    moves.clear()
                    moves.append(MoveScore(Move(place1, place2), score2))
                    return

                if debug:
                    var board_value = self.board.board_value(values)
                    if self.turn:
                        board_value = -board_value
                    debug_assert(board_value.value == board_score.value + score1.value + score2.value)

                var board2 = board.copy()
                board2.place_stone(values, place2, self.turn)
                var max_opp_score = board2.max_score(1 - self.turn)
                var move_score = board_score + score1 + score2 - max_opp_score
                if move_score != Score.loss():
                    heap_add[less](MoveScore(Move(place1, place2), move_score), moves)

    fn play_move(self, move: Move, values: List[List[Scores]]) -> Self:
        var new_state = self.copy()
        new_state.board.place_stone(values, move._p1, new_state.turn)
        if move._p1 != move._p2:
            new_state.board.place_stone(new_state.values, move._p2, new_state.turn)
        new_state.turn = 1 - new_state.turn
        new_state.plies += 1
        if new_state.plies > Self.max_plies:
            return Score.draw()
        return new_state^

    fn score(self) -> Score:
        return self.board._score

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)

struct Connect6[size: Int, max_moves: Int, max_places: Int, max_plies: Int](TGame):
    comptime State = State[Self.size, win_stones]
    comptime Move = State.Move

    var values: List[List[Scores]]

    fn __init__(out self):
        self.values = value_table[win_stones, values]()

    fn moves(self, state: Self.State) -> List[MoveScore[Move]]:
        var moves = List[MoveScore[Move]](capacity=Self.max_moves)
        state.moves(moves, self.values)
        if state.plies == Self.max_plies:
            moves[-1].score = Score.draw()
            return [moves[-1]]
        return moves^

    fn play_move(self, state: Self.State, move: Move) -> self.State:
        return state.play_move(move, self.values)
