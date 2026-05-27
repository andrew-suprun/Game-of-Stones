from std.python import Python, PythonObject
from std.utils import Variant

from engine import Place

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
struct Stone(ImplicitlyCopyable, Writable):
    var place: Place
    var color: Int
    var selected: Bool


@fieldwise_init
struct NoEvent(Movable, Writable):
    pass


@fieldwise_init
struct EnterKey(Movable, Writable):
    pass


@fieldwise_init
struct LeftKey(Movable, Writable):
    pass


@fieldwise_init
struct RightKey(Movable, Writable):
    pass


@fieldwise_init
struct Quit(Movable, Writable):
    pass


@fieldwise_init
struct MouseClick(Movable, Writable):
    var place: Place


comptime Event = Variant[NoEvent, EnterKey, LeftKey, RightKey, Quit, MouseClick]


struct Ui[board_size: Int](Copyable):
    comptime d = window_height / (Self.board_size + 1)
    comptime r = Self.d / 2

    var pygame: PythonObject
    var window: PythonObject

    def __init__(out self, name: String) raises:
        self.pygame = Python.import_module("pygame")
        self.pygame.init()
        self.window = self.pygame.display.set_mode(Python.tuple(window_height, window_width))
        self.pygame.display.set_caption("Game of Stones - " + name)
        self.draw([])

    def poll_event(self) raises -> Event:
        return self._get_event(0)

    def wait_event(self) raises -> Event:
        return self._get_event(-1)

    def wait_event(self, timeout: Int) raises -> Event:
        return self._get_event(timeout)

    def _get_event(self, timeout: Int) raises -> Event:
        while True:
            var event = self.pygame.event.wait() if timeout < 0 else self.pygame.event.poll() if timeout == 0 else self.pygame.event.wait(timeout)
            if event.type == self.pygame.NOEVENT:
                return Event(NoEvent())

            elif event.type == self.pygame.QUIT:
                return Event(Quit())

            elif event.type == self.pygame.KEYDOWN:
                if event.key == self.pygame.K_LEFT:
                    return Event(LeftKey())

                if event.key == self.pygame.K_RIGHT:
                    return Event(RightKey())

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

        for stone in stones:
            color = color_black if stone.color == black else color_white
            var center = Self.board_to_window(stone.place.x, stone.place.y)
            self.pygame.draw.circle(self.window, color, center, Self.r - 2)
            if stone.selected:
                self.pygame.draw.circle(self.window, color_selected, center, Self.r / 5)

        self.pygame.display.flip()

    @staticmethod
    def board_to_window(x: Int8, y: Int8, out result: PythonObject) raises:
        result = Python.tuple(Int(x + 1) * Self.d, Int(y + 1) * Self.d)
