from sys import env_get_string
from hashlib.hasher import Hasher
from builtin.sort import sort

from score import Score, is_win
from game import TGame, TMove, MoveScore, Decision
from board import Board, Place, first

alias debug = env_get_string["ASSERT_MODE", ""]()

alias win_stones = 5
alias scores = List[Float32](0, 1, 5, 25, 125)

@register_passable("trivial")
struct Move(TMove):
    var _place: Place

    fn __init__(out self):
        self = Self(Place())

    fn __init__(out self, p1: Place):
        self._place = p1

    @implicit
    fn __init__(out self, move: StringSlice) raises:
        self._place = Place(String(move))

    @implicit
    fn __init__(out self, move: StringLiteral) raises:
        self = Self(String(move))

    fn __hash__[H: Hasher](self, mut hasher: H):
        hasher.update(self._place)

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self._place)
    
struct Gomoku[size: Int, max_places: Int](TGame):
    alias Move = Move

    var board: Board[scores, size, win_stones]
    var turn: Int
    var _hash: UInt64

    fn __init__(out self):
        self.board = Board[scores, size, win_stones]()
        self.turn = 0
        self._hash = 0

    fn moves(self, max_moves: Int) -> List[MoveScore[Move]]:
        @parameter
        fn less(a: MoveScore[Move], b: MoveScore[Move]) -> Bool:
            return a.score < b.score

        var moves = List[MoveScore[Move]]()
        var places = self.board.places(self.turn, max_moves)
        var board_score = self.board._score if self.turn == first else -self.board._score
        for place in places:
            var score = self.board.score(place, self.turn)
            if is_win(score):
                return [MoveScore(Move(place), score)]
            moves.append(MoveScore(Move(place), board_score + self.board.score(place, self.turn) / 2))
        return moves

    fn play_move(mut self, move: Move):
        self.board.place_stone(move._place, self.turn)
        if self.turn == first:
            self._hash += hash(move)
        else:
            self._hash -= hash(move)
        self.turn = 1 - self.turn

    fn score(self) -> Score:
        return self.board.score()

    fn is_terminal(self) -> Bool:
        return self.board.is_terminal()

    fn hash(self) -> Int:
        return Int(self._hash)

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)