from board import Board, Place, first
from game import TGame, TMove, Score, iswin
from heap import heap_add

alias win_stones = 6
alias scores = List[Float32](0, 1, 5, 25, 125, 625)

@register_passable("trivial")
struct Move(TMove):
    var _p1: Place
    var _p2: Place

    fn __init__(out self, p1: Place, p2: Place):
        self._p1 = p1
        self._p2 = p2

    @implicit
    fn __init__(out self, move: String) raises:
        var tokens = move.split("-")
        self._p1 = Place(tokens[0])
        if len(tokens) == 2:
            self._p2 = Place(tokens[1])
        else:
            self._p2 = self._p1

    @implicit
    fn __init__(out self, move: StringLiteral) raises:
        var tokens = String(move).split("-")
        self._p1 = Place(tokens[0])
        if len(tokens) == 2:
            self._p2 = Place(tokens[1])
        else:
            self._p2 = self._p1

    fn __eq__(self, other: Move) -> Bool:
        return self._p1 == other._p1 and self._p2 == other._p2

    fn __ne__(self, other: Move) -> Bool:
        return self._p1 != other._p1 or self._p2 != other._p2

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self._p1 != self._p2:
            writer.write(self._p1, "-", self._p2)
        else:
            writer.write(self._p1)

struct Connect6[size: Int, max_moves: Int, max_places: Int](TGame):
    alias Move = Move
    alias Score = Score

    var board: Board[scores, size, win_stones, max_places]
    var turn: Int

    fn __init__(out self):
        self.board = Board[scores, size, win_stones, max_places]()
        self.turn = 0

    fn moves(self) -> List[(Move, Score)]:
        @parameter
        fn move_less(a: (Move, Score), b: (Move, Score)) -> Bool:
            return a[1] < b[1]

        var places = self.board.places(self.turn)
        if len(places) < max_places:
            return []

        var moves = List[(Move, Score)](capacity = max_moves)
        var board_score = self.board._score if self.turn == first else -self.board._score
        for i in range(len(places) - 1):
            var place1 = places[i]
            var score1 = self.board.score(place1, self.turn)
            if iswin(score1):
                return [(Move(place1, place1), score1)]

            var board1 = self.board
            board1.place_stone(place1, self.turn)

            for j in range(i + 1, len(places)):
                var place2 = places[j]
                var score2 = board1.score(place2, self.turn)

                if iswin(score2):
                    return [(Move(place1, place2), score2)]

                var board2 = board1
                board2.place_stone(place2, self.turn)
                max_opp_score = board2.max_score(1 - self.turn)

                heap_add[max_moves, move_less]((Move(place1, place2), board_score + score1 + score2 - max_opp_score), moves)
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
