from sys import env_get_string
from hashlib.hasher import Hasher

from score import Score
from game import TGame, TMove, MoveScore
from board import Board, Place, first

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

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self._place)


struct Gomoku[size: Int, max_places: Int, max_plies: Int](TGame):
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

    fn moves(self) -> List[MoveScore[Move]]:
        var moves = List[MoveScore[Move]](capacity=max_places)
        self._moves(moves)
        if self.plies == Self.max_plies:
            moves[-1].score = Score.draw()
            return [moves[-1]]
        return moves^

    fn _moves(self, mut moves: List[MoveScore[Move]]):
        @parameter
        fn less(a: MoveScore[Move], b: MoveScore[Move]) -> Bool:
            return a.score < b.score

        var places = List[Place](capacity=max_places)
        self.board.places(self.turn, places)
        var board_score = self.board._score if self.turn == first else -self.board._score
        for place in places:
            var score = self.board.score(place, self.turn)
            if score.is_win():
                moves.clear()
                moves.append(MoveScore(Move(place), score))
                return
            moves.append(MoveScore(Move(place), board_score + score.value / 2))

    fn play_move(mut self, move: Move) -> Score:
        self.board.place_stone(move._place, self.turn)
        if self.turn == first:
            self._hash += hash(move)
        else:
            self._hash -= hash(move)
        self.turn = 1 - self.turn
        self.plies += 1
        if self.plies > Self.max_plies:
            return Score.draw()
        return self.board._score

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
