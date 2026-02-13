from time import perf_counter_ns
from python import Python, PythonObject
import random

from score import Score
from board import Place
from traits import TTree, TGame

comptime window_height = 1000
comptime window_width = 1000

comptime black = 0
comptime white = 1

comptime color_background = "burlywood4"
comptime color_black = "black"
comptime color_white = "white"
comptime color_selected = "deepskyblue3"
comptime color_line = "gray20"

comptime duration = 1000


fn game_of_stones[name: StaticString, board_size: Int, Tree: TTree, Game: TGame, stones_per_move: Int]() raises:
    var pygame = Python.import_module("pygame")
    pygame.init()
    var window = pygame.display.set_mode(Python.tuple(window_height, window_width))
    pygame.display.set_caption("Game of Stones - " + name)

    var done = False
    while not done:
        var game = GameOfStones[board_size, Tree, stones_per_move](pygame, window)
        done = game.run()


struct GameOfStones[board_size: Int, Tree: TTree, stones_per_move: Int]:
    comptime d = window_height / (Self.board_size + 1)
    comptime r = Self.d / 2

    var pygame: PythonObject
    var window: PythonObject
    var moves: List[Self.Tree.Game.Move]
    var selected: List[Place]
    var game: Self.Tree.Game
    var tree: Self.Tree
    var turn: Int
    var search_complete: Bool
    var game_complete: Bool
    var game_complete_confirmed: Bool
    var app_complete: Bool
    var played_moves: List[Self.Tree.Game.Move]

    fn __init__(out self, pygame: PythonObject, window: PythonObject):
        self.pygame = pygame
        self.window = window
        self.moves = List[Self.Tree.Game.Move]()
        self.selected = List[Place]()
        self.game = Self.Tree.Game()
        self.tree = Self.Tree()
        self.turn = black
        self.search_complete = False
        self.game_complete = False
        self.game_complete_confirmed = False
        self.app_complete = False
        self.played_moves = List[Self.Tree.Game.Move]()

    fn run(mut self) raises -> Bool:
        self.play_move(Self.first_black_move(), 0, 0)

        while not self.app_complete and not self.game_complete_confirmed:
            self.human_move()
            self.engine_move()
        return self.app_complete

    fn play_move(mut self, move: Self.Tree.Game.Move, score: Score, time_ms: UInt) raises:
        self.moves.append(move)
        self.selected.clear()
        var board_score = self.game.play_move(move)
        self.tree = Self.Tree()
        print("move", move, end="")
        if score != 0:
            print(" score", score, end="")

        if time_ms > 0:
            print(" ms", time_ms, end="")

        print()
        # print(self.game)
        if board_score.is_decisive():
            self.game_complete = True

        self.turn = 1 - self.turn
        self.search_complete = False

    fn human_move(mut self) raises:
        while True:
            var event = self.pygame.event.wait()
            if event.type == self.pygame.QUIT:
                self.app_complete = True
                return

            elif event.type == self.pygame.KEYDOWN:
                if event.key == self.pygame.K_ESCAPE:
                    if len(self.moves) == 1:
                        continue
                    var moves = self.moves^
                    self.moves = List[Self.Tree.Game.Move]()
                    _ = moves.pop()
                    self.selected.clear()
                    self.game_complete = False
                    self.tree = Self.Tree()
                    self.game = Self.Tree.Game()
                    for move in moves:
                        self.play_move(move, 0, 0)

                elif event.key == self.pygame.K_RETURN:
                    if self.game_complete:
                        self.game_complete_confirmed = True
                        return
                    if not self.selected:
                        return
                    if len(self.selected) == self.stones_per_move:
                        var move: Self.Tree.Game.Move
                        var place1 = self.selected[0]
                        if self.stones_per_move == 1:
                            move = Self.Tree.Game.Move(String(place1))
                        else:
                            var place2 = self.selected[1]
                            move = Self.Tree.Game.Move(String(place1) + "-" + String(place2))
                        self.play_move(move, 0, 0)
                        self.selected.clear()
                        self.draw()
                        return

            elif event.type == self.pygame.MOUSEBUTTONDOWN:
                if self.game_complete:
                    return
                var x = (Int(py=event.pos[0]) - Self.r) / Self.d
                var y = (Int(py=event.pos[1]) - Self.r) / Self.d
                if x >= 0 and x < Self.board_size and y >= 0 and y < Self.board_size:
                    var place = Place(x, y)
                    if place in self.selected:
                        if place == self.selected[0]:
                            _ = self.selected.pop(0)
                        elif len(self.selected) == 2:
                            _ = self.selected.pop(1)
                    elif len(self.selected) < self.stones_per_move and self.is_empty(place):
                        self.selected.append(place)
            self.draw()

    fn is_empty(self, place: Place) raises -> Bool:
        for move in self.moves:
            var places = String(move).split("-")
            for place_str in places:
                var board_place = Place(String(place_str))
                if board_place == place:
                    return False
        return True

    fn engine_move(mut self) raises:
        if self.app_complete or self.game_complete:
            return

        if len(self.moves) == 1:
            var move = Self.first_white_move()
            self.play_move(move, 0, 0)
            self.draw()
            return

        var start = perf_counter_ns()
        var move = self.tree.search(self.game, duration)
        self.play_move(move.move, move.score, (perf_counter_ns() - start) / 1_000_000)
        self.draw()

    fn draw(self) raises:
        self.window.fill(color_background)

        for i in range(1, Self.board_size + 1):
            self.pygame.draw.line(
                self.window,
                color_line,
                Python.tuple(Self.d, i * Self.d),
                Python.tuple(Self.board_size * Self.d, i * Self.d),
            )
            self.pygame.draw.line(
                self.window,
                color_line,
                Python.tuple(i * Self.d, Self.d),
                Python.tuple(i * Self.d, Self.board_size * Self.d),
            )

        var turn = black
        var color: String
        for move in self.moves:
            color = color_black if turn == black else color_white
            var places = String(move).split("-")
            for place_str in places:
                var place = Place(String(place_str))
                self.pygame.draw.circle(self.window, color, board_to_window[Self.d](place.x, place.y), Self.r - 2)
            turn = 1 - turn

        var last_move = self.moves[-1]
        var places = String(last_move).split("-")
        for place_str in places:
            var place = Place(String(place_str))
            self.pygame.draw.circle(
                self.window,
                color_selected,
                board_to_window[Self.d](place.x, place.y),
                Self.r / 5,
            )

        color = color_black if turn == black else color_white
        for place in self.selected:
            self.pygame.draw.circle(self.window, color, board_to_window[Self.d](place.x, place.y), Self.r - 2)
            self.pygame.draw.circle(
                self.window,
                color_selected,
                board_to_window[Self.d](place.x, place.y),
                Self.r / 5,
            )

        self.pygame.display.flip()

    @staticmethod
    fn first_black_move() raises -> Self.Tree.Game.Move:
        var x = Self.board_size / 2
        var place = Place(x, x)
        if Self.stones_per_move == 1:
            return Self.Tree.Game.Move(String(place))
        else:
            return Self.Tree.Game.Move(String(place) + "-" + String(place))

    @staticmethod
    fn first_white_move() raises -> Self.Tree.Game.Move:
        var x = Self.board_size / 2
        var places = List[Place]()
        for j in range(x-1, x+2):
            for i in range(x-1, x+2):
                if i != x or j != x:
                    places.append(Place(i, j))
        random.seed()
        random.shuffle(places)

        if Self.stones_per_move == 1:
            return Self.Tree.Game.Move(String(places[0]))
        else:
            return Self.Tree.Game.Move(String(places[0]) + "-" + String(places[1]))


def board_to_window[d: Int](x: Int8, y: Int8, out result: PythonObject):
    result = Python.tuple((Int(x) + 1) * d, (Int(y) + 1) * d)
