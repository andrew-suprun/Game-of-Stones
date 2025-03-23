from python import Python, PythonObject
from collections import InlineArray, Set
import time

alias board_size = 19
alias window_height = 800
alias window_width = 800

alias empty = 0
alias black = 1
alias white = 2

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

struct Game:
    var pygame: PythonObject
    var window: PythonObject
    var running: Bool
    var places: List[Place]
    var selected: Set[Place]

    fn __init__(out self) raises:
        self.pygame = Python.import_module("pygame")
        self.pygame.init()
        self.window = self.pygame.display.set_mode((window_height, window_width))
        self.pygame.display.set_caption("Game of Stones")
        self.running = False
        self.places = List[Place](Place(9, 9, black), Place(8, 9, black), Place(0, 0, white), Place(18, 18, white))
        self.selected = Set[Place](Place(9, 9, black), Place(0, 0, white), Place(18, 18, white))


    fn run(mut self) raises:
        self.running = True
        while self.running:
            self.handle_events(self.pygame.event.get())
            self.window.fill(color_background)

            for i in range(1, board_size+1):
                self.pygame.draw.line(self.window, color_line, (d, i*d), (board_size*d, i*d))
                self.pygame.draw.line(self.window, color_line, (i*d, d), (i*d, board_size*d))

            for place in self.places:
                var color = color_black if place[].stone == black else color_white
                self.pygame.draw.circle(self.window, color, board_to_window(place[].x, place[].y), r - 1)

            for place in self.selected:
                self.pygame.draw.circle(self.window, color_selcted, board_to_window(place[].x, place[].y), r//5)

            self.pygame.display.flip()
            time.sleep(.1)
        self.pygame.quit()

    fn handle_events(mut self, events: PythonObject) raises:
        if len(events) == 0:
            return
        for event in events:
            if event.type == self.pygame.MOUSEMOTION:
                continue
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
                    continue
                print(event.pos, x, y)

        

fn board_to_window(x: Int, y: Int, out result: (Int, Int)):
    result = ((x + 1) * d, (y + 1) * d)

fn main() raises:
    var game = Game()
    game.run()