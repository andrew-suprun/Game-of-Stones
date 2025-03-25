from sys import argv
from collections import InlineArray, Set
from time import perf_counter_ns
from python import Python, PythonObject
import random

from game_of_stones import Gomoku, Connect6
from tree import Move, Place
from tree.tree import Tree

alias board_size = 19
alias window_height = 1000
alias window_width = 1000

alias black = 0
alias white = 1

alias human = 0
alias engine = 1

alias gomoku = 0
alias connect6 = 1

alias color_background = "burlywood4"
alias color_black = "black"
alias color_white = "white"
alias color_selcted = "deepskyblue3"
alias color_line = "gray20"

alias d = window_height // (board_size + 1)
alias r = d // 2

alias G = Gomoku[19, 20]
alias C6 = Connect6[19, 32, 16]

alias TG = Tree[G, 40]
alias TC6 = Tree[C6, 30]

struct State:
    var name: Int
    var places: List[List[Place]]
    var selected: List[List[Place]]
    var gomoku: G
    var connect6: C6
    var gomoku_tree: TG
    var connect6_tree: TC6
    var turn: Int
    var max_selected: Int
    var search_complete: Bool

    fn __init__(out self, name: Int):
        self.name = name
        self.places = List(List[Place](), List[Place]())
        self.selected = List(List[Place](), List[Place]())
        self.gomoku = G()
        self.connect6 = C6()
        self.gomoku_tree = TG()
        self.connect6_tree = TC6()
        self.turn = black
        self.max_selected = 1 if name == gomoku else 2
        self.search_complete = False

    fn play_move(mut self, move: Move):
        if self.name == gomoku:
            self.gomoku.play_move(move)
            self.gomoku_tree.reset(self.gomoku)
            print("move", move, self.gomoku.decision())
            print(self.gomoku)
        else:
            self.connect6.play_move(move)
            self.connect6_tree.reset(self.connect6)
            print("move", move, self.connect6.decision())
            print(self.connect6)
        
        self.turn = 1 - self.turn
        self.selected[self.turn].clear()
        self.search_complete = False

    fn best_move(mut self, out move: Move):
        if self.name == gomoku:
            move = self.gomoku_tree.best_move()
        else:
            move = self.connect6_tree.best_move()


    fn expand_tree(mut self, out complete: Bool):
        if not self.search_complete:
            if self.name == gomoku:
                self.search_complete = self.gomoku_tree.expand(self.gomoku)
            else:
                self.search_complete = self.connect6_tree.expand(self.connect6)
        return self.search_complete

    fn debug_print(self):
        print("black")
        for place in self.places[black]:
            print("  place", place[].x, place[].y)
        for place in self.selected[black]:
            print("    selected", place[].x, place[].y)
        print("white")
        for place in self.places[white]:
            print("  place", place[].x, place[].y)
        for place in self.selected[white]:
            print("    selected", place[].x, place[].y)

struct Game:
    var pygame: PythonObject
    var window: PythonObject
    var state: State
    var running: Bool

    fn __init__(out self, name: Int) raises:
        self.pygame = Python.import_module("pygame")
        self.pygame.init()
        self.window = self.pygame.display.set_mode((window_height, window_width))
        if name == gomoku:
            self.pygame.display.set_caption("Game of Stones - Gomoku")
        else:
            self.pygame.display.set_caption("Game of Stones - Connect6")
        self.state = State(name)
        self.running = True

    fn run(mut self) raises:
        self.state = State(self.state.name)
        self.state.places[black].append(Place(9, 9))
        self.state.selected[black].append(Place(9, 9))
        self.state.play_move(Move("j10"))

        while self.running:
            self.human_move()
            self.engine_move()

        self.pygame.quit()

    fn human_move(mut self) raises:
        while True:
            var event = self.pygame.event.wait()
            if event.type == self.pygame.QUIT:
                self.running = False
                return
            
            elif event.type == self.pygame.KEYDOWN:
                if event.key == self.pygame.K_ESCAPE:
                    print("TODO: undo move")
                elif event.key == self.pygame.K_RETURN:
                    if not self.state.places[white] and not self.state.selected[white]:
                        return
                    if len(self.state.selected[self.state.turn]) == self.state.max_selected:
                        var place1 = self.state.selected[self.state.turn][-1]
                        if self.state.max_selected == 1:
                            self.state.play_move(Move(place1, place1))
                        else:
                            var place2 = self.state.selected[self.state.turn][-2]
                            self.state.play_move(Move(place1, place2))
                        
                        self.draw()
                        return

            elif event.type == self.pygame.MOUSEBUTTONDOWN:
                var x = Int(event.pos[0]-r)//d
                var y = Int(event.pos[1]-r)//d
                if x >=0 and x < board_size and y >= 0 and y < board_size:
                    var place = Place(x, y)
                    if place in self.state.places[1 - self.state.turn]:
                        continue
                    if place in self.state.places[self.state.turn]:
                        if place in self.state.selected[self.state.turn]:
                            var idx = self.state.places[self.state.turn].index(place)
                            _ = self.state.places[self.state.turn].pop(idx)
                            _ = self.state.selected[self.state.turn].pop(idx)
                        else:
                            continue
                    elif len(self.state.selected[self.state.turn]) < self.state.max_selected:
                        self.state.places[self.state.turn].append(place)
                        self.state.selected[self.state.turn].append(place)
            self.draw()

    fn engine_move(mut self) raises:
        if not self.running: return

        if not self.state.places[white] and not self.state.selected[white]:
            var move = first_white_move(self.state.name)
            self.play_move(move)
            self.draw()
            return

        var deadline = perf_counter_ns() + 1_000_000_000
        var done = False
        var sim = 0
        while not done and perf_counter_ns() < deadline:
            if sim % 1000 == 0:
                var event = self.pygame.event.poll()
                if event.type == self.pygame.QUIT:
                    self.running = False
                    return
            done = self.state.expand_tree()
            sim += 1

        var move = self.state.best_move()
        print("best move", move, "sim", sim, "done", done)
        self.play_move(move)
        self.draw()

    fn play_move(mut self, move: Move) raises:
        self.state.places[self.state.turn].append(move.p1)
        self.state.selected[self.state.turn].append(move.p1)
        if move.p1 != move.p2:
            self.state.places[self.state.turn].append(move.p2)
            self.state.selected[self.state.turn].append(move.p2)
        self.state.play_move(move)

    fn draw(self) raises:
        self.window.fill(color_background)

        for i in range(1, board_size+1):
            self.pygame.draw.line(self.window, color_line, (d, i*d), (board_size*d, i*d))
            self.pygame.draw.line(self.window, color_line, (i*d, d), (i*d, board_size*d))

        for turn in range(2):
            var color = color_black if turn == black else color_white
            for place in self.state.places[turn]:
                self.pygame.draw.circle(self.window, color, board_to_window(place[].x, place[].y), r - 1)
            for place in self.state.selected[turn]:
                self.pygame.draw.circle(self.window, color_selcted, board_to_window(place[].x, place[].y), r//5)

        self.pygame.display.flip()

fn first_white_move(name: Int, out move: Move):
    var places = List[Place]()
    for j in range(8, 11):
        for i in range(8, 11):
            if i != 9 or j != 9:
                places.append(Place(Int8(i), Int8(j)))
    random.seed()
    random.shuffle(places)

    if name == gomoku:
        move = Move(places[0], places[0])
    else:
        move = Move(places[0], places[1])


fn board_to_window(x: Int8, y: Int8, out result: (Int, Int)):
    result = ((Int(x) + 1) * d, (Int(y) + 1) * d)

fn main() raises:
    var name = connect6
    var args = argv()
    if len(args) > 1 and (args[1] == "gomoku"):
        name = gomoku

    var game = Game(name)
    game.run()