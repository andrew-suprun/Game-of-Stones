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

fn game_of_stones[name: StaticString, Game: TGame, c: Score, stones_per_move: Int]() raises -> Bool:
    var pygame = Python.import_module("pygame")
    pygame.init()
    var window = pygame.display.set_mode(Python.tuple(window_height, window_width))
    pygame.display.set_caption("Game of Stones - " + name)

    var done = False
    while not done:
        var game = GameOfStones[Game, c, stones_per_move](pygame, window)
        done = game.run()
    return done

struct GameOfStones[Game: TGame, c: Score, stones_per_move: Int]:
    var pygame: PythonObject
    var window: PythonObject
    var moves: List[Game.Move]
    var selected: List[Place]
    var game: Game
    var tree: Tree[Game, c]
    var turn: Int
    var search_complete: Bool
    var game_complete: Bool
    var game_complete_confirmed: Bool
    var app_complete: Bool
    var played_moves: List[Game.Move]

    fn __init__(out self, pygame: PythonObject, window: PythonObject):
        self.pygame = pygame
        self.window = window
        self.moves = List[Game.Move]()
        self.selected = List[Place]()
        self.game = Game()
        self.tree = Tree[Game, c]()
        self.turn = black
        self.search_complete = False
        self.game_complete = False
        self.game_complete_confirmed = False
        self.app_complete = False
        self.played_moves = List[Game.Move]()

    fn run(mut self) raises -> Bool:
        var move = Game.Move("j10")
        self.play_move(move)

        while not self.app_complete and not self.game_complete_confirmed:
            self.human_move()
            self.engine_move()
        return self.app_complete

    fn play_move(mut self, move: Game.Move) raises:
        self.moves.append(move)
        self.selected.clear()
        self.game.play_move(move)
        self.tree = Tree[Game, c]()
        print("move", move, self.game.decision())
        print(self.game)
        if self.game.decision() != "no-decision":
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
                    _ = self.moves.pop()
                    _ = self.moves.pop()
                    self.selected.clear()
                    self.game_complete = False
                    self.tree = Tree[Game, c]()
                    self.game = Game()
                    var moves = self.moves
                    for move in moves:
                        self.play_move(move)

                elif event.key == self.pygame.K_RETURN:
                    if self.game_complete:
                        self.game_complete_confirmed = True
                        return
                    # turn the table on first white move
                    if len(self.moves) == 1:
                        return
                    if len(self.selected) == self.stones_per_move:
                        var move: Game.Move
                        var place1 = self.selected[0]
                        if self.stones_per_move == 1:
                            move = Game.Move(String(place1))
                        else:
                            var place2 = self.selected[1]
                            move = Game.Move(String(place1) + "-" + String(place2))
                        self.play_move(move)
                        self.selected.clear()
                        self.draw()
                        return

            elif event.type == self.pygame.MOUSEBUTTONDOWN:
                if self.game_complete:
                    return
                var x = Int(event.pos[0]-r)//d
                var y = Int(event.pos[1]-r)//d
                print(len(self.selected), self.stones_per_move)
                if x >=0 and x < board_size and y >= 0 and y < board_size:
                    var place = Place(x, y)
                    if place in self.selected:
                        if place == self.selected[0]:
                            _ = self.selected.pop(0)
                        elif len(self.selected) == 2:
                            _ = self.selected.pop(1)
                    elif len(self.selected) < self.stones_per_move:
                        self.selected.append(place)
            self.draw()

    fn engine_move(mut self) raises:
        if self.app_complete or self.game_complete: return

        if len(self.moves) == 1:
            var move = Self.first_white_move()
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
        self.play_move(move)
        self.draw()

    fn draw(self) raises:
        self.window.fill(color_background)

        for i in range(1, board_size+1):
            self.pygame.draw.line(self.window, color_line, Python.tuple(d, i*d), Python.tuple(board_size*d, i*d))
            self.pygame.draw.line(self.window, color_line, Python.tuple(i*d, d), Python.tuple(i*d, board_size*d))
        
        var turn = black
        var color: String
        for move in self.moves:
            color = color_black if turn == black else color_white
            var places = String(move).split("-")
            for place_str in places:
                var place = Place(place_str)
                self.pygame.draw.circle(self.window, color, board_to_window(place.x, place.y), r - 2)
            turn = 1 - turn

        var last_move = self.moves[-1]
        var places = String(last_move).split("-")
        for place_str in places:
            var place = Place(place_str)
            self.pygame.draw.circle(self.window, color_selcted, board_to_window(place.x, place.y), r//5)

        color = color_black if turn == black else color_white
        for place in self.selected:
            self.pygame.draw.circle(self.window, color, board_to_window(place.x, place.y), r - 2)
            self.pygame.draw.circle(self.window, color_selcted, board_to_window(place.x, place.y), r//5)

        self.pygame.display.flip()


    fn undo_moves(mut self):
            _ = self.moves.pop(-1)
            _ = self.moves.pop(-1)
            self.selected.clear()
            self.tree = Tree[Game, c]()
            print("undo")
            print(self.game)
        
    fn best_move(mut self, out move: Game.Move):
        move = self.tree.best_move()

    fn expand_tree(mut self, out complete: Bool):
        if not self.search_complete:
            self.search_complete = self.tree.expand(self.game)
        return self.search_complete

    @staticmethod
    fn first_white_move() raises -> Game.Move:
        var places = List[Place]()
        for j in range(8, 11):
            for i in range(8, 11):
                if i != 9 or j != 9:
                    places.append(Place(Int8(i), Int8(j)))
        random.seed()
        random.shuffle(places)

        if stones_per_move == 1:
            return Game.Move(String(places[0]))
        else:
            return Game.Move(String(places[0]) + "-" + String(places[1]))


def board_to_window(x: Int8, y: Int8, out result: PythonObject):
    result = Python.tuple((Int(x) + 1) * d, (Int(y) + 1) * d)

