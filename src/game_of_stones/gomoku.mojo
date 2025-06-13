from game import Game, Move, Score, win, draw

from .heap import add
from .board import Board, Place

alias max_stones = 5
alias values = List[Score](0, 1, 5, 25, 125, win)

struct Gomoku[size: Int, max_moves: Int](Game):
    var board: Board[values, size, max_stones, max_moves]
    var turn: Int
    var top_places: List[Place]
    var history: List[Move]

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_moves]()
        self.turn = 0
        self.top_places = List[Place]()
        self.history = List[Move]()

    fn name(self, out name: String):
        name = "gomoku"

    fn top_moves(mut self, mut move_scores: List[(Move, Score)]):
        @parameter
        fn less(a: (Move, Score), b: (Move, Score), out r: Bool):
            r = a[1] < b[1]

        move_scores.clear()
        self.board.top_places(self.turn, self.top_places)

        if not self.top_places:
            move_scores.append((Move, Score)(Move(0, 0, 0, 0), draw))
            return

        var has_draw = False

        for place in self.top_places:
            var score = self.board.getscores(place)[self.turn]

            if score == win:
                move_scores.clear()
                move_scores.append((Move, Score)(Move(place, place), win))
                return
            elif score == 0:
                if not has_draw:
                    add[(Move, Score), max_moves, less]((Move, Score)(Move(place, place), draw), move_scores)
                    has_draw = True
            else:
                add[(Move, Score), max_moves, less]((Move, Score)(Move(place, place), score), move_scores)

    fn play_move(mut self, move: Move):
        self.history.append(move)

        self.board.place_stone(move.p1, self.turn)
        self.turn = 1 - self.turn

    fn undo_move(mut self):
        if len(self.history) == 0:
            return

        self.turn = 1 - self.turn
        self.history.shrink(len(self.history)-1)
        self.board.remove_stone()

    fn decision(self, out decision: String):
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)

