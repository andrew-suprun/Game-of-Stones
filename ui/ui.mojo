from std.python import Python, PythonObject
from std.utils import Variant

comptime window_height = 800
comptime window_width = 800

comptime black = 0
comptime white = 1

comptime color_background = "burlywood4"
comptime color_black = "black"
comptime color_white = "white"
comptime color_selected = "deepskyblue3"
comptime color_line = "gray20"


@fieldwise_init
struct Place(ImplicitlyCopyable, Writable):
    var x: Int
    var y: Int


@fieldwise_init
struct Stone(ImplicitlyCopyable, Writable):
    var place: Place
    var black: Bool
    var selected: Bool


@fieldwise_init
struct EnterKey(Movable, Writable):
    pass


@fieldwise_init
struct EsqKey(Movable, Writable):
    pass


@fieldwise_init
struct Quit(Movable, Writable):
    pass


@fieldwise_init
struct MouseClick(Movable, Writable):
    var place: Place


comptime Event = Variant[EnterKey, EsqKey, Quit, MouseClick]


struct Ui[board_size: Int]:
    comptime d = window_height / (Self.board_size + 1)
    comptime r = Self.d / 2

    var pygame: PythonObject
    var window: PythonObject

    def __init__(out self, name: String) raises:
        self.pygame = Python.import_module("pygame")
        self.pygame.init()
        self.window = self.pygame.display.set_mode(Python.tuple(window_height, window_width))
        self.pygame.display.set_caption("Game of Stones - " + name)

    def poll_event(self) raises -> Event:
        while True:
            var event = self.pygame.event.wait()
            if event.type == self.pygame.QUIT:
                return Event(Quit())

            elif event.type == self.pygame.KEYDOWN:
                if event.key == self.pygame.K_ESCAPE:
                    return Event(EsqKey())

                elif event.key == self.pygame.K_RETURN:
                    return Event(EnterKey())

            elif event.type == self.pygame.MOUSEBUTTONDOWN:
                var x = (Int(py=event.pos[0]) - Self.r) / Self.d
                var y = (Int(py=event.pos[1]) - Self.r) / Self.d
                if x >= 0 and x < Self.board_size and y >= 0 and y < Self.board_size:
                    return Event(MouseClick(Place(x, y)))

    def draw(self, stones: List[Stone]) raises:
        self.window.fill(color_background)

        for i in range(1, Self.board_size + 1):
            self.pygame.draw.line(self.window, color_line, Python.tuple(Self.d, i * Self.d), Python.tuple(Self.board_size * Self.d, i * Self.d))
            self.pygame.draw.line(self.window, color_line, Python.tuple(i * Self.d, Self.d), Python.tuple(i * Self.d, Self.board_size * Self.d))

        for stone in stones:
            color = color_black if stone.black else color_white
            self.pygame.draw.circle(self.window, color, Self.board_to_window(stone.place.x, stone.place.y), Self.r - 2)
            if stone.selected:
                self.pygame.draw.circle(self.window, color_selected, Self.board_to_window(stone.place.x, stone.place.y), Self.r / 5)

        self.pygame.display.flip()

    @staticmethod
    def board_to_window(x: Int, y: Int, out result: PythonObject) raises:
        result = Python.tuple((x + 1) * Self.d, (y + 1) * Self.d)
