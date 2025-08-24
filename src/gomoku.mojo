from sys import env_get_string
from hashlib.hasher import Hasher

from score import Score, is_decisive
from game import TGame, TMove, MoveScore
from board import Board, Place, size, first

alias debug = env_get_string["ASSERT_MODE", ""]()

alias win_stones = 5
alias values = List[Float32](0, 1, 5, 25, 125)


@register_passable("trivial")
struct Move(TMove):
    var _place: Place

    fn __init__(out self):
        self = Self(Place())

    fn __init__(out self, p1: Place):
        self._place = p1

    @implicit
    fn __init__(out self, move: String) raises:
        self._place = Place(String(move))

    fn __hash__[H: Hasher](self, mut hasher: H):
        hasher.update(self._place)

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self._place)


struct Gomoku[max_places: Int](TGame):
    alias Move = Move

    var board: Board[values, win_stones]
    var turn: Int
    var _hash: UInt64

    fn __init__(out self):
        self.board = Board[values, win_stones]()
        self.turn = 0
        self._hash = 0

    fn __copyinit__(out self, other: Self, /):
        self.board = other.board.copy()
        self.turn = other.turn
        self._hash = other._hash

    fn copy(self) -> Self:
        return self

    fn score(self) -> Score:
        var moves = List[MoveScore[Move]](capacity=1)
        self._moves(moves)
        return moves[0].score

    fn moves(self) -> List[MoveScore[Move]]:
        var moves = List[MoveScore[Move]](capacity=max_places)
        self._moves(moves)
        return moves

    fn _moves(self, mut moves: List[MoveScore[Move]]):
        @parameter
        fn less(a: MoveScore[Move], b: MoveScore[Move]) -> Bool:
            return a.score < b.score

        var places = List[Place](capacity = max_places)
        self.board.places(self.turn, places)
        var board_score = self.board._score if self.turn == first else -self.board._score
        for place in places:
            var score = self.board.score(place, self.turn)
            if is_decisive(score):
                moves.append(MoveScore(Move(place), score))
            moves.append(MoveScore(Move(place), board_score + self.board.score(place, self.turn) / 2))

    fn play_move(mut self, move: Move) -> Score:
        self.board.place_stone(move._place, self.turn)
        if self.turn == first:
            self._hash += hash(move)
        else:
            self._hash -= hash(move)
        self.turn = 1 - self.turn
        return self.board._score

    fn hash(self) -> Int:
        return Int(self._hash)

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
