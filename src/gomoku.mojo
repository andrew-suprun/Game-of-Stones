from game import TGame, TMove

from heap import heap_add
from board import Board, Place, is_decisive, is_win, is_loss, is_draw

alias max_stones = 5
alias values = List[Score](0, 1, 5, 25, 125)

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

    @always_inline
    fn is_decisive(self) -> Bool:
        return is_decisive(self.score)

    @always_inline
    fn is_win(self) -> Bool:
        return is_win(self.score)

    @always_inline
    fn is_loss(self) -> Bool:
        return is_loss (self.score)

    @always_inline
    fn is_draw(self) -> Bool:
        return is_draw(self.score)

    fn __str__(self, out r: String):
        r = String.write(self)

    fn write_to[W: Writer](self, mut writer: W):
        if self.p1 != self.p2:
            writer.write(self.p1, "-", self.p2)
        else:
            writer.write(self.p1)

struct Gomoku[size: Int, max_moves: Int](TGame):
    alias Move = Move

    var board: Board[values, size, max_stones, max_moves]
    var turn: Int
    var top_places: List[Place]

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_moves]()
        self.turn = 0
        self.top_places = List[Place]()

    fn name(self, out name: String):
        name = "gomoku"

    fn top_moves(mut self, mut move_scores: List[Move]):
        @parameter
        fn less(a: self.Move, b: self.Move, out r: Bool):
            r = a.score[1] < b.score[1]

        move_scores.clear()
        self.board.top_places(self.turn, self.top_places)

        if not self.top_places:
            move_scores.append(Move(Move(0, 0, 0, 0), draw))
            return

        var has_draw = False

        for place in self.top_places:
            var score = self.board.getscores(place)[self.turn]

            if score == win:
                move_scores.clear()
                move_scores.append(Move(Move(place, place), win))
                return
            elif score == 0:
                if not has_draw:
                    heap_add[Move, max_moves, less](Move(Move(place, place), draw), move_scores)
                    has_draw = True
            else:
                heap_add[Move, max_moves, less](Move(Move(place, place), self.score + score), move_scores)

    fn play_move(mut self, move: self.Move):
        self.board.place_stone(move.p1, self.turn)
        self.turn = 1 - self.turn

    fn undo_move(mut self):
        self.turn = 1 - self.turn
        self.board.remove_stone()

    fn decision(self, out decision: String):
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)

