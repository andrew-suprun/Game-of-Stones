from game import Game, Move, Score, win, draw

from .heap import add
from .board import Board, Place

alias max_stones = 6
alias values = List[Score](0, 1, 5, 25, 125, 625, win)

struct Connect6[size: Int, max_moves: Int, max_places: Int](Game):
    var board: Board[values, size, max_stones, max_places]
    var turn: Int
    var top_places: List[Place]

    fn __init__(out self):
        self.board = Board[values, size, max_stones, max_places]()
        self.turn = 0
        self.top_places = List[Place]()

    fn name(self, out name: String):
        name = "connect6"

    fn top_moves(mut self, mut move_scores: List[(Move, Score)]):
        @parameter
        fn less(a: (Move, Score), b: (Move, Score), out r: Bool):
            r = a[1] < b[1]

        move_scores.clear()
        self.board.top_places(self.turn, self.top_places)

        if len(self.top_places) < 2:
            if len(self.top_places) == 1:
                var top_place = self.top_places[0]
                move_scores.append((Move, Score)(Move(top_place, top_place), draw))
            else:
                move_scores.append((Move, Score)(Move(0, 0, 0, 0), draw))
            return

        for i in range(len(self.top_places) - 1):
            var place1 = self.top_places[i]
            var score1 = self.board.getscores(place1)[self.turn]
            if score1 == win:
                move_scores.clear()
                move_scores.append((Move, Score)(Move(place1, place1), win))
                return

            self.board.place_stone(place1, self.turn)

            for j in range(i + 1, len(self.top_places)):
                var place2 = self.top_places[j]
                var score2 = self.board.getscores(place2)[self.turn]

                if score2 == win:
                    move_scores.clear()
                    move_scores.append((Move, Score)(Move(place1, place2), win))
                    self.board.remove_stone()
                    return
                elif score1 + score2 == 0:
                    add[(Move, Score), max_moves, less]((Move, Score)(Move(place1, place2), draw), move_scores)
                else:
                    add[(Move, Score), max_moves, less]((Move, Score)(Move(place1, place2), score1 + score2), move_scores)

            self.board.remove_stone()

    fn play_move(mut self, move: Move):
        self.board.place_stone(move.p1, self.turn)
        if move.p1 != move.p2:
            self.board.place_stone(move.p2, self.turn)
        self.turn = 1 - self.turn

    fn undo_move(mut self):
        self.board.remove_stone()
        self.board.remove_stone()
        self.turn = 1 - self.turn

    fn decision(self, out decision: String):
        return self.board.decision()

    fn __str__(self, out str: String):
        return String(self.board)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.board)
