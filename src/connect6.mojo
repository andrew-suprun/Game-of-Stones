from sys import env_get_string
from hashlib.hasher import Hasher

from score import Score
from game import TGame, TMove, MoveScore
from board import Board, Place, first
from heap import heap_add

alias debug = env_get_string["ASSERT_MODE", ""]()

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625)


@register_passable("trivial")
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

    fn __hash__[H: Hasher](self, mut hasher: H):
        hasher.update(self._p1)
        hasher.update(self._p2)

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self._p1 != self._p2:
            writer.write(self._p1, "-", self._p2)
        else:
            writer.write(self._p1)


struct Connect6[size: Int, max_moves: Int, max_places: Int, max_plies: Int](TGame):
    alias Move = Move

    var board: Board[size, values, win_stones]
    var turn: Int
    var plies: Int
    var _hash: UInt64

    fn __init__(out self):
        self.board = Board[size, values, win_stones]()
        self.turn = 0
        self.plies = 0
        self._hash = 0

    fn __copyinit__(out self, other: Self, /):
        self.board = other.board.copy()
        self.turn = other.turn
        self.plies = other.plies
        self._hash = other._hash

    fn copy(self) -> Self:
        return self

    fn move(self) -> MoveScore[Move]:
        var moves = List[MoveScore[Move]](capacity=1)
        self._moves(moves)
        if self.plies == Self.max_plies:
            moves[0].score = Score.draw()
        return moves[0]

    fn moves(self) -> List[MoveScore[Move]]:
        var moves = List[MoveScore[Move]](capacity=max_moves)
        self._moves(moves)
        if self.plies == Self.max_plies:
            moves[-1].score = Score.draw()
            return [moves[-1]]
        return moves

    fn _moves(self, mut moves: List[MoveScore[Move]]):
        @parameter
        fn less(a: MoveScore[Move], b: MoveScore[Move]) -> Bool:
            return a.score < b.score

        var places = List[Place](capacity=max_places)
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

            var board1 = self.board
            board1.place_stone(place1, self.turn)

            for j in range(i + 1, len(places)):
                var place2 = places[j]
                var score2 = board1.score(place2, self.turn)

                if score2.is_win():
                    moves.clear()
                    moves.append(MoveScore(Move(place1, place2), score2))
                    return

                var board2 = board1
                if debug:
                    var board_value = board2.board_value(values)
                    if self.turn:
                        board_value = -board_value
                    debug_assert(board_value == board_score + score1 + score2)

                board2.place_stone(place2, self.turn)
                var max_opp_score = board2.max_score(1 - self.turn)
                var move_score = board_score + score1 + score2 - max_opp_score
                heap_add[less](MoveScore(Move(place1, place2), move_score), moves)

    fn play_move(mut self, move: Move) -> Score:
        self.board.place_stone(move._p1, self.turn)
        if move._p1 != move._p2:
            self.board.place_stone(move._p2, self.turn)
        if self.turn == first:
            self._hash += hash(move)
        else:
            self._hash -= hash(move)
        self.turn = 1 - self.turn
        self.plies += 1
        if self.plies > Self.max_plies:
            return Score.draw()
        return self.board._score

    fn hash(self) -> Int:
        return Int(self._hash)

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
