from sys import argv
from collections import InlineArray, Set
import time
from python import Python, PythonObject

from game_of_stones import Gomoku, Connect6
from tree import Move
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

@value
struct Place(KeyElement):
    var x: Int
    var y: Int
    var stone: Int
    
    fn __eq__(self, other: Self, out result: Bool):
        return self.x == other.x and self.y == other.y

    fn __ne__(self, other: Self, out result: Bool):
        return self.x != other.x or self.y != other.y

    fn __hash__(self, out result: UInt):
        return hash(self.x + self.y * board_size)

alias G = Gomoku[19, 12]
alias C6 = Connect6[19, 32, 16]

struct State:
    var name: Int
    var places: List[Place]
    var selected: Set[Place]
    var gomoku: G
    var connect6: C6
    var gomoku_tree: Tree[G, 30]
    var connect6_tree: Tree[C6, 30]
    var turn: Int
    var player: Int
    var search_complete: Bool

    fn __init__(out self, name: Int):
        self.name = name
        self.places = List[Place]()
        self.selected = Set[Place]()
        self.gomoku = G()
        self.connect6 = C6()
        self.gomoku_tree = Tree[G, 30]()
        self.connect6_tree = Tree[C6, 30]()
        self.turn = black
        self.player = engine
        self.search_complete = False

    fn play_move(mut self, move: Move):
        self.selected.clear()
        if self.name == gomoku:
            self.gomoku.play_move(move)
        else:
            self.connect6.play_move(move)
        
        var place1 = Place(Int(move.p1.x), Int(move.p1.y), self.turn)
        var place2 = Place(Int(move.p2.x), Int(move.p2.y), self.turn)
        self.places.append(place1)
        self.selected.add(place1)
        if place1 != place2:
            self.places.append(place2)
            self.selected.add(place2)
        
        self.turn = 1 - self.turn
        self.player = 1 - self.player
        self.search_complete = False

    fn expand_tree(mut self, out complete: Bool):
        if not self.search_complete:
            if self.name == gomoku:
                self.search_complete = self.gomoku_tree.expand(self.gomoku)
            else:
                self.search_complete = self.connect6_tree.expand(self.connect6)
        return self.search_complete

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
        self.state.play_move(Move("j10"))

        while self.running:
            if self.state.expand_tree():
                self.handle_event(self.pygame.event.poll())
            else:
                self.handle_event(self.pygame.event.wait())
                
            self.window.fill(color_background)

            for i in range(1, board_size+1):
                self.pygame.draw.line(self.window, color_line, (d, i*d), (board_size*d, i*d))
                self.pygame.draw.line(self.window, color_line, (i*d, d), (i*d, board_size*d))

            for place in self.state.places:
                var color = color_black if place[].stone == black else color_white
                self.pygame.draw.circle(self.window, color, board_to_window(place[].x, place[].y), r - 1)

            for place in self.state.selected:
                self.pygame.draw.circle(self.window, color_selcted, board_to_window(place[].x, place[].y), r//5)

            self.pygame.display.flip()
            time.sleep(.1)
        self.pygame.quit()

    fn handle_event(mut self, event: PythonObject) raises:
        if event.type == self.pygame.MOUSEMOTION:
            ...
        elif event.type == self.pygame.QUIT:
            self.running = False
        elif event.type == self.pygame.KEYDOWN:
            if event.key == self.pygame.K_ESCAPE:
                print("TODO: undo move")
            elif event.key == self.pygame.K_RETURN:
                print("TODO: play move")
        elif event.type == self.pygame.MOUSEBUTTONDOWN:
            var x = Int(event.pos[0]-r)//d
            var y = Int(event.pos[1]-r)//d
            if x < 0 or x >= board_size or y < 0 or y >= board_size:
                ...
            print(event.pos, x, y)

fn board_to_window(x: Int, y: Int, out result: (Int, Int)):
    result = ((x + 1) * d, (y + 1) * d)

fn main() raises:
    var name = gomoku
    var args = argv()
    if len(args) > 1 and (args[1] == "connect6" or args[1] == "c6"):
        name = connect6

    var game = Game(name)
    game.run()