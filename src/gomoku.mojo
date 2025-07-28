from game import TGame, TMove, Score, iswin, isdraw
from board import Board, Place, first

alias win_stones = 5
alias values = List[Float32](0, 1, 5, 25, 125)

@register_passable("trivial")
struct Move(TMove):
    var _place: Place

    fn __init__(out self, place: Place):
        self._place = place

    @implicit
    fn __init__(out self, move: String) raises:
        self._place = Place(move)

    @implicit
    fn __init__(out self, move: StringLiteral) raises:
        self._place = Place(move)

    fn __eq__(self, other: Move) -> Bool:
        return self._place == other._place

    fn __ne__(self, other: Move) -> Bool:
        return self._place != other._place

    fn __str__(self) -> String:
        return String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self._place)

struct Gomoku[size: Int, max_moves: Int](TGame):
    alias Move = Move

    var board: Board[values, size, win_stones, max_moves]
    var turn: Int

    fn __init__(out self):
        self.board = Board[values, size, win_stones, max_moves]()
        self.turn = first

    fn moves(self) -> List[(Move, Score)]:
        @parameter
        fn move_less(a: (Move, Score), b: (Move, Score)) -> Bool:
            return a[1] < b[1]

        var places = self.board.places(self.turn)
        if len(places) < max_moves:
            return []

        var moves = List[(Move, Score)](capacity = len(places))
        var board_score = self.board._score if self.turn == first else -self.board._score
        for place in places:
            var score = self.board.score(place, self.turn)
            if iswin(score):
                return [(Move(place), score)]
            if isdraw(score):
                moves.append((Move(place), score))
            else:
                moves.append((Move(place), board_score + self.board.score(place, self.turn) / 2))
        return moves

    fn play_move(mut self, move: self.Move):
        self.board.place_stone(move._place, self.turn)
        self.turn = 1 - self.turn

    fn decision(self) -> StaticString:
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
