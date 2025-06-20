from game import TGame, TMove

from .heap import add
from .board import Board, Place, win

alias max_stones = 6
alias values = List[Score](0, 1, 5, 25, 125, 625)

@fieldwise_init
@register_passable("trivial")
struct Move(TMove):
    var p1: Place
    var p2: Place
    var score: Score

    fn __init__(out self):
        self.p1 = Place()
        self.p2 = Place()
        self.score = 0

    fn __init__(out self, x1: Int, y1: Int, x2: Int, y2: Int):
        self.p1 = Place(x1, y1)
        self.p2 = Place(x2, y2)
        self.score = 0

    fn __init__(out self, move: String) raises:
        var tokens = move.split("-")
        self.p1 = Place(tokens[0])
        if len(tokens) == 2:
            self.p2 = Place(tokens[1])
        else:
            self.p2 = self.p1
        self.score = 0

    @always_inline
    fn score(self) -> Score:
        return self.score


    @always_inline
    fn set_score(mut self, score: Score):
        self.score = score

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        result = self.p1 == other.p1 and self.p2 == other.p2 or
            self.p1 == other.p2 and self.p1 == other.p1

    @always_inline
    fn __ne__(self, other: Self) -> Bool:
        return not (self == other)

    fn __str__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self.p1 != self.p2:
            writer.write(self.p1, "-", self.p2)
        else:
            writer.write(self.p1)

struct Connect6[size: Int, max_moves: Int, max_places: Int](TGame):
    alias Move = Move
    var board: Board[values, size, max_stones, max_places]
    var turn: Int
    var top_places: List[Place]
    var history: List[Self.Move]

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_places]()
        self.turn = 0
        self.top_places = List[Place]()
        self.history = List[Self.Move]()

    fn name(self, out name: String):
        name = "connect6"

    fn top_moves(mut self, mut move_scores: List[self.Move]):
        @parameter
        fn less(a: self.Move, b: self.Move, out r: Bool):
            r = a.score[1] < b.score[1]

        move_scores.clear()
        self.board.top_places(self.turn, self.top_places)

        if len(self.top_places) < 2:
            if len(self.top_places) == 1:
                var top_place = self.top_places[0]
                move_scores.append(Move(Move(top_place, top_place), draw))
            else:
                move_scores.append(Move(Move(0, 0, 0, 0), draw))
            return

        for i in range(len(self.top_places) - 1):
            var place1 = self.top_places[i]
            var score1 = self.board.getscores(place1)[self.turn]
            if score1 == win:
                move_scores.clear()
                move_scores.append(Move(Move(place1, place1), win))
                return

            self.board.place_stone(place1, self.turn)

            for j in range(i + 1, len(self.top_places)):
                var place2 = self.top_places[j]
                var score2 = self.board.getscores(place2)[self.turn]

                if score2 == win:
                    move_scores.clear()
                    move_scores.append(Move(Move(place1, place2), win))
                    self.board.remove_stone()
                    return
                var score = -self.score + score1 + score2 if score1 + score2 == 0 else draw
                heap_add[Move, max_moves, less](Move(Move(place1, place2), score), move_scores)

            self.board.remove_stone()

    fn play_move(mut self, move: self.Move):
        self.history.append(move)
        self.board.place_stone(move.p1, self.turn)
        if move.p1 != move.p2:
            self.board.place_stone(move.p2, self.turn)
        self.turn = 1 - self.turn

    fn undo_move(mut self):
        var move = self.history.pop()
        self.board.remove_stone()
        if move.p1 != move.p2:
            self.board.remove_stone()
        self.turn = 1 - self.turn

    fn decision(self, out decision: String):
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
