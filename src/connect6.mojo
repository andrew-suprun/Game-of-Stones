from hashlib.hasher import Hasher
from builtin.sort import sort
from utils.numerics import isinf, neg_inf

from game import TGame, TMove, Score, Terminal, MoveScore, Decision
from board import Board, Place, first
from heap import heap_add

alias win_stones = 6
alias scores = List[Float32](0, 1, 5, 25, 125, 625)

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
    fn __init__(out self, move: StringSlice) raises:
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

    @implicit
    fn __init__(out self, move: StringLiteral) raises:
        self = Self(String(move))

    fn __hash__[H: Hasher](self, mut hasher: H):
        hasher.update(self._p1)
        hasher.update(self._p2)

    fn __eq__(self, other: Self) -> Bool:
        return (self._p1 == other._p1 and self._p2 == other._p2) or
                (self._p1 == other._p2 and self._p2 == other._p1)

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self._p1 != self._p2:
            writer.write(self._p1, "-", self._p2)
        else:
            writer.write(self._p1)
    
struct Connect6[size: Int, max_places: Int](TGame):
    alias Move = Move
    alias Score = Score

    var board: Board[scores, size, win_stones, max_places]
    var turn: Int
    var _hash: UInt64

    fn __init__(out self):
        self.board = Board[scores, size, win_stones, max_places]()
        self.turn = 0
        self._hash = 0

    fn moves(self, max_moves: Int) -> List[MoveScore[Move]]:
        @parameter
        fn less(a: MoveScore[Move], b: MoveScore[Move]) -> Bool:
            return a.score < b.score

        @parameter
        fn greater(a: MoveScore[Move], b: MoveScore[Move]) -> Bool:
            return a.score > b.score

        var moves = List[MoveScore[Move]]()

        var places = self.board.places(self.turn)
        debug_assert(len(places) > 1)

        var board_score = self.board._score if self.turn == first else -self.board._score
        for i in range(len(places) - 1):
            var place1 = places[i]
            var score1 = self.board.score(place1, self.turn)
            if isinf(score1):
                return [MoveScore(Move(place1, place1), score1, True)]

            var board1 = self.board
            board1.place_stone(place1, self.turn)

            for j in range(i + 1, len(places)):
                var place2 = places[j]
                var score2 = board1.score(place2, self.turn)

                if isinf(score2):
                    return [MoveScore(Move(place1, place2), score2, True)]

                var board2 = board1
                board2.place_stone(place2, self.turn)
                var board_value = board2.board_value(scores)
                if self.turn:
                    board_value = -board_value
                var max_opp_score = board2.max_score(1 - self.turn)
                debug_assert(board_value == board_score + score1 + score2)
                var move_score = board_score + score1 + score2 - max_opp_score
                heap_add[less](MoveScore(Move(place1, place2), move_score, False), max_moves, moves)
                # print("\n### board", board_score, Move(place1, place2, move_score, False), "|", score1, score2, "opp", max_opp_score, end="")
        sort[greater](moves)
        return moves

    fn play_move(mut self, move: Move):
        self.board.place_stone(move._p1, self.turn)
        if move._p1 != move._p2:
            self.board.place_stone(move._p2, self.turn)
        if self.turn == first:
            self._hash += hash(move)
        else:
            self._hash -= hash(move)
        self.turn = 1 - self.turn

    fn decision(self) -> Decision:
        return self.board.decision()

    fn hash(self) -> Int:
        return Int(self._hash)

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)