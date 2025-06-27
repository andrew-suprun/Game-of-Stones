from sys import argv, env_get_string
from time import perf_counter_ns
from python import Python, PythonObject
import random
import sys

from board import Place
from game import TGame, TMove, Score
from gomoku import Gomoku

alias game = env_get_string["game"]()

from tree import Tree

alias board_size = 19
alias window_height = 1000
alias window_width = 1000

alias black = 0
alias white = 1

alias color_background = "burlywood4"
alias color_black = "black"
alias color_white = "white"
alias color_selcted = "deepskyblue3"
alias color_line = "gray20"

alias d = window_height // (board_size + 1)
alias r = d // 2

struct GameOfStones[Game: TGame, c: Score, max_selected: Int]:
    var places: List[List[Place]]
    var selected: List[List[Place]]
    var game: Game
    var tree: Tree[Game, c]
    var turn: Int
    var search_complete: Bool
    var game_complete: Bool
    var pygame: PythonObject
    var window: PythonObject
    var app_complete: Bool
    var game_complete_confirmed: Bool
    var played_moves: List[Game.Move]

    fn __init__(out self, name: String) raises:
        self.places = List(List[Place](), List[Place]())
        self.selected = List(List[Place](), List[Place]())
        self.game = Game()
        self.tree = Tree[Game, c]()
        self.turn = black
        self.search_complete = False
        self.game_complete = False
        self.app_complete = False
        self.game_complete_confirmed = False
        self.played_moves = List[Game.Move]()
        self.pygame = Python.import_module("pygame")
        self.pygame.init()
        self.window = self.pygame.display.set_mode(Python.tuple(window_height, window_width))
        self.pygame.display.set_caption("Game of Stones - " + name)

    fn run(mut self) raises -> Bool:
        var move = Game.Move("j10")
        self.add_stones(move)
        self.play_move(move)

        while not self.app_complete and not self.game_complete_confirmed:
            self.human_move()
            self.engine_move()
        if self.app_complete:
            self.pygame.quit()
        return self.app_complete

    fn human_move(mut self) raises:
        while True:
            var event = self.pygame.event.wait()
            if event.type == self.pygame.QUIT:
                self.app_complete = True
                return
            
            elif event.type == self.pygame.KEYDOWN:
                if event.key == self.pygame.K_ESCAPE:
                    var stones = len(self.places[black]) + len(self.places[white]) - len(self.selected[self.turn])
                    if stones <= self.max_selected + 1:
                        continue
                    for stone in range(2):
                        while self.selected[stone]:
                            var place = self.selected[stone].pop()
                            var idx = self.places[stone].index(place)
                            _ = self.places[stone].pop(idx)

                    for _ in range(self.max_selected):
                        var place = self.places[self.turn][-1]
                        self.remove_place(place)

                    for i in range(self.max_selected):
                        var place = self.places[1-self.turn][-1 - i]
                        self.selected[1 - self.turn].append(place)

                    self.game_complete = False

                    self.undo_moves()

                elif event.key == self.pygame.K_RETURN:
                    if self.game_complete:
                        self.game_complete_confirmed = True
                        return
                    # turn the table on first white move
                    if not self.places[white]:
                        return
                    if len(self.selected[self.turn]) == self.max_selected:
                        var place1 = self.selected[self.turn][-1]
                        if self.max_selected == 1:
                            self.play_move(Game.Move(String(place1)))
                        else:
                            var place2 = self.selected[self.turn][-2]
                            self.play_move(Game.Move(String(place1) + "-" + String(place2)))
                        
                        self.draw()
                        return

            elif event.type == self.pygame.MOUSEBUTTONDOWN:
                if self.game_complete:
                    return
                var x = Int(event.pos[0]-r)//d
                var y = Int(event.pos[1]-r)//d
                if x >=0 and x < board_size and y >= 0 and y < board_size:
                    var place = Place(x, y)
                    if place in self.places[1 - self.turn]:
                        continue
                    if place in self.selected[self.turn]:
                        self.remove_place(place)
                    elif len(self.selected[self.turn]) < self.max_selected and
                            place not in self.places[self.turn]:
                        self.add_selected(place)
            self.draw()

    fn engine_move(mut self) raises:
        if self.app_complete or self.game_complete: return

        if not self.places[white] and not self.selected[white]:
            var move = Self.first_white_move()
            self.add_stones(move)
            self.play_move(move)
            self.draw()
            return

        var deadline = perf_counter_ns() + 1_000_000_000
        var done = False
        var sim = 0
        while not done and perf_counter_ns() < deadline:
            var event = self.pygame.event.poll()
            if event.type == self.pygame.QUIT:
                self.app_complete = True
                return
            var deadline2 = perf_counter_ns() + 16_000_000
            while not done and perf_counter_ns() < deadline2:
                done = self.expand_tree()
                sim += 1
        print("sims", sim)

        var move = self.tree.best_move()
        self.add_stones(move)
        self.play_move(move)
        self.draw()

    fn add_stones(mut self, move: Game.Move) raises:
        var places = String(move).split("-")
        for place in places:
            self.add_selected(Place(place))

    fn play_move(mut self, move: Game.Move) raises:
        self.game.play_move(move)
        self.tree = Tree[Game, c]()
        print("move", move, self.game.decision())
        print(self.game)
        if self.game.decision() != "no-decision":
            self.game_complete = True

        self.turn = 1 - self.turn
        self.selected[self.turn].clear()
        self.search_complete = False

    fn draw(self) raises:
        self.window.fill(color_background)

        for i in range(1, board_size+1):
            self.pygame.draw.line(self.window, color_line, Python.tuple(d, i*d), Python.tuple(board_size*d, i*d))
            self.pygame.draw.line(self.window, color_line, Python.tuple(i*d, d), Python.tuple(i*d, board_size*d))

        for turn in range(2):
            var color = color_black if turn == black else color_white
            for place in self.places[turn]:
                self.pygame.draw.circle(self.window, color, board_to_window(place.x, place.y), r - 2)
            for place in self.selected[turn]:
                self.pygame.draw.circle(self.window, color_selcted, board_to_window(place.x, place.y), r//5)

        self.pygame.display.flip()


    fn undo_moves(mut self):
            # TODO: implement undo_move()
            self.tree = Tree[Game, c]()
            print("undo")
            print(self.game)
        
    fn best_move(mut self, out move: Game.Move):
        move = self.tree.best_move()

    fn expand_tree(mut self, out complete: Bool):
        if not self.search_complete:
            self.search_complete = self.tree.expand(self.game)
        return self.search_complete

    fn add_selected(mut self, place: Place):
        self.places[self.turn].append(place)
        self.selected[self.turn].append(place)

    fn remove_place(mut self, place: Place):
        try:
            var idx = self.places[self.turn].index(place)
            _ = self.places[self.turn].pop(idx)
            idx = self.selected[self.turn].index(place)
            _ = self.selected[self.turn].pop(idx)
        except:
            pass

    fn debug_print(self):
        print("  black")
        for place in self.places[black]:
            print("    place", place.x, place.y)
        for place in self.selected[black]:
            print("      selected", place.x, place.y)
        print("  white")
        for place in self.places[white]:
            print("    place", place.x, place.y)
        for place in self.selected[white]:
            print("      selected", place.x, place.y)

    @staticmethod
    fn first_white_move() raises -> Game.Move:
        var places = List[Place]()
        for j in range(8, 11):
            for i in range(8, 11):
                if i != 9 or j != 9:
                    places.append(Place(Int8(i), Int8(j)))
        random.seed()
        random.shuffle(places)

        if max_selected == 1:
            return Game.Move(String(places[0]))
        else:
            return Game.Move(String(places[0]) + "-" + String(places[1]))


def board_to_window(x: Int8, y: Int8, out result: PythonObject):
    result = Python.tuple((Int(x) + 1) * d, (Int(y) + 1) * d)

