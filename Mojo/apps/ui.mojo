from python import Python, PythonObject
import time

alias board_size = 19
alias window_height = 800
alias window_width = 800
alias background_color = "burlywood4"
alias d = window_height // (board_size + 1)
alias r = d // 2

struct Game:
    var pygame: PythonObject
    var window: PythonObject
    var running: Bool

    fn __init__(out self) raises:
        self.pygame = Python.import_module("pygame")
        self.pygame.init()
        self.window = self.pygame.display.set_mode((window_height, window_width))
        self.pygame.display.set_caption("Game of Stones")
        self.running = False


    fn run(mut self) raises:
        self.running = True
        while self.running:
            self.handle_events(self.pygame.event.get())

            self.window.fill(background_color)

            for i in range(1, board_size+1):
                self.pygame.draw.line(self.window, "black", (d, i*d), (board_size*d, i*d))
                self.pygame.draw.line(self.window, "black", (i*d, d), (i*d, board_size*d))

            self.pygame.display.flip()
            time.sleep(.1)
        self.pygame.quit()

    fn handle_events(mut self, events: PythonObject) raises:
        if len(events) == 0:
            return
        print("events", events)
        for event in events:
            if event.type == self.pygame.QUIT:
                self.running = False
            elif event.type == self.pygame.KEYDOWN:
                if event.key == self.pygame.K_ESCAPE:
                    print("TODO: undo move")
                elif event.key == self.pygame.K_RETURN:
                    print("TODO: play move")

fn main() raises:
    var game = Game()
    game.run()