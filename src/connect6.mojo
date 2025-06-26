from game import TGame, TMove, Score
from heap import heap_add
from board import Board, Place, first

alias max_stones = 6
alias values = List[Score](0, 1, 5, 25, 125, 625)

@register_passable("trivial")
struct Move(TMove):
    alias Score = Score

    var _p1: Place
    var _p2: Place
    var _score: Score

    fn __init__(out self):
        self = Self.__init__(Place(), Place(), 0)


    fn __init__(out self, p1: Place = Place(0, 0), p2: Place = Place(0, 0), score: Score = 0):
        self._p1 = p1
        self._p2 = p2
        self._score = score

    @implicit
    fn __init__(out self, move: String) raises:
        var tokens = move.split("-")
        self._p1 = Place(tokens[0])
        if len(tokens) == 2:
            self._p2 = Place(tokens[1])
        else:
            self._p2 = self._p1
        self._score = 0

    @implicit
    fn __init__(out self, move: StringLiteral) raises:
        var tokens = String(move).split("-")
        self._p1 = Place(tokens[0])
        if len(tokens) == 2:
            self._p2 = Place(tokens[1])
        else:
            self._p2 = self._p1
        self._score = 0

    fn score(self) -> Self.Score:
        return self._score

    fn set_score(mut self, score: Self.Score):
        self._score = score

    fn __eq__(self, other: Move) -> Bool:
        return self._p1 == other._p1 and self._p2 == other._p2

    fn __ne__(self, other: Move) -> Bool:
        return self._p1 != other._p1 or self._p2 != other._p2

    fn __str__(self) -> String:
        return String.write(self)

    fn __repr__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self._p1 != self._p2:
            writer.write(self._p1, "-", self._p2)
        else:
            writer.write(self._p1)

struct Connect6[size: Int, max_moves: Int, max_places: Int](TGame):
    alias Move = Move
    var board: Board[values, size, max_stones, max_places]
    var turn: Int

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_places]()
        self.turn = 0

    fn moves(self) -> List[self.Move]:
        @parameter
        fn move_less(a: self.Move, b: self.Move) -> Bool:
            return a.score() < b.score()

        var places = self.board.places(self.turn)
        if len(places) < max_places:
            return [Move(score = Score.draw())]

        var moves = List[Move](capacity = max_moves)
        var board_score = self.board._score if self.turn == first else -self.board._score
        for i in range(len(places) - 1):
            var place1 = places[i]
            var score1 = self.board.score(place1, self.turn)
            if score1.iswin():
                return [Move(place1, place1, Score.win())]

            var board = self.board
            board.place_stone(place1, self.turn)

            for j in range(i + 1, len(places)):
                var place2 = places[j]
                var score2 = board.score(place2, self.turn)

                if score2.iswin():
                    return [Move(place1, place2, Score.win())]
                heap_add[max_moves, move_less](Move(place1, place2, board_score + score1 + score2), moves)

        return moves

    fn play_move(mut self, move: self.Move):
        self.board.place_stone(move._p1, self.turn)
        if move._p1 != move._p2:
            self.board.place_stone(move._p2, self.turn)
        self.turn = 1 - self.turn

    fn decision(self) -> StaticString:
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
