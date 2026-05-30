from std.time import perf_counter_ns
from std.random import seed, shuffle

from engine import Connect6, Gomoku
from engine import Mcts, AlphaBetaNegamax, PrincipalVariationNegamax
from engine import Score, MoveScore, Place
from ui import Ui, Event, Stone, Place as UiPlace, EnterKey, LeftKey, RightKey, WindowResize, Quit, MouseClick, black, white

comptime duration = 100
comptime board_size = 19
comptime BoardUi = Ui[board_size]

comptime GomokuGame = Gomoku[board_size, 22]
comptime Connect6Game = Connect6[board_size, 26, 20]

# comptime Game = GomokuGame
comptime Game = Connect6Game
comptime name = reflect[Game].base_name()

# comptime Tree = Mcts[Game, Score(0.25)] # Gomoku
# comptime Tree = Mcts[Game, Score(0.35)]  # Connect6
# comptime Tree = AlphaBetaNegamax[Game]
comptime Tree = PrincipalVariationNegamax[Game]


def main() raises:
    var done = False
    var ui = BoardUi(name)
    while not done:
        var game = GameOfStones()
        done = game.run(ui)


struct GameOfStones:
    var stones: List[Stone]
    var undo_stones: List[Stone]
    var n_selected: Int
    var human_turn: Bool
    var game_complete: Bool
    var game_complete_confirmed: Bool
    var app_complete: Bool

    def __init__(out self) raises:
        self.stones = List[Stone]()
        self.undo_stones = List[Stone]()
        self.human_turn = True
        self.n_selected = 0
        self.game_complete = False
        self.game_complete_confirmed = False
        self.app_complete = False

    def run(mut self, mut ui: BoardUi) raises -> Bool:
        var first_move = self.first_black_move()
        print(t"\n{first_move} ", end="")
        self.stones.append(Stone(first_move, black, True))
        ui.draw(self.stones)

        while not self.app_complete and not self.game_complete_confirmed:
            if self.human_turn:
                self.human_move(ui)
            else:
                self.engine_move()
            ui.draw(self.stones)
        print()
        return self.app_complete

    def last_stone(self) -> ref[self.stones] Stone:
        return self.stones[len(self.stones) - 1]

    def add_move(mut self, move: String) raises:
        var turn = 1 - self.last_stone().color
        var places = move.split("-")
        for place_str in places:
            place = Place(String(place_str))
            self.stones.append(Stone(place, turn, True))
        self.select_last_move()

    def remove_move(mut self):
        var popped_stone = self.stones.pop()
        if self.last_stone().color == popped_stone.color:
            _ = self.stones.pop()
        self.select_last_move()

    def select_last_move(mut self):
        for ref stone in self.stones:
            stone.selected = False

        self.stones[len(self.stones) - 1].selected = True
        if len(self.stones) > 2 and self.stones[len(self.stones) - 1].color == self.stones[len(self.stones) - 2].color:
            self.stones[len(self.stones) - 2].selected = True

    def human_move(mut self, mut ui: BoardUi) raises:
        while True:
            var event = ui.wait_event()
            if event.isa[Quit]():
                self.app_complete = True
                break

            elif event.isa[WindowResize]():
                ui.set_window_size(event[WindowResize].window_size)
                break

            elif event.isa[EnterKey]():
                if self.game_complete:
                    self.game_complete_confirmed = True
                    return
                self.human_turn = False
                break

            elif event.isa[LeftKey]():
                self.undo()
                break

            elif event.isa[RightKey]():
                self.redo()
                break

            elif event.isa[MouseClick]():
                self.handle_mouse(event)
                break

    def undo(mut self) raises:
        if len(self.stones) == 1:
            return

        if self.n_selected:
            while self.n_selected:
                _ = self.stones.pop()
                self.n_selected -= 1
            return

        print("undo ", end="")
        var color = self.stones[len(self.stones) - 1].color
        while color == self.stones[len(self.stones) - 1].color:
            self.undo_stones.append(self.stones.pop())
        self.select_last_move()
        self.game_complete = False
        self.game_complete_confirmed = False

    def redo(mut self) raises:
        if not self.undo_stones:
            return

        var stone1 = self.undo_stones.pop()
        self.stones.append(stone1)
        if name == "Connect6" and self.undo_stones:
            var stone2 = self.undo_stones.pop()
            self.stones.append(stone2)
            print(t"{stone1.place}-{stone2.place} ", end="")
        else:
            print(t"{stone1.place} ", end="")

        self.select_last_move()

    def handle_mouse(mut self, event: Event) raises:
        if self.game_complete:
            return

        self.undo_stones.clear()
        ref click_event = event[MouseClick]
        ref last_stone = self.last_stone()

        for i, stone in enumerate(self.stones):
            if click_event.place == stone.place:
                if stone.color == last_stone.color and stone.selected and self.n_selected:
                    _ = self.stones.pop(i)
                    self.n_selected -= 1
                return
        else:
            var color = last_stone.color if self.n_selected > 0 else 1 - last_stone.color
            var stone = Stone(click_event.place, color, True)
            self.stones.append(stone)
            self.n_selected += 1
            if name == "Connect6" and self.n_selected < 2:
                return

            self.human_turn = False
            self.n_selected = 0
            self.select_last_move()

            var game = self.replay_moves()
            if game.score().is_decisive():
                self.game_complete = True
                self.human_turn = True

    def engine_move(mut self) raises:
        if self.game_complete:
            return

        if len(self.stones) == 1:
            var move = self.first_white_move()
            print(t"{move} ", end="")
            self.add_move(move)
            self.human_turn = True
            return

        var tree = Tree()
        var game = self.replay_moves()
        var pv = tree.search(game, duration)
        var move = pv[0]
        game.play_move(move.move)
        print(t"{move} ", end="")
        print(t"\ngame score: {game.score()}")
        if game.score().is_decisive():
            self.game_complete = True
        self.add_move(String(move.move))
        self.select_last_move()
        self.human_turn = True

    def replay_moves(self, out game: Game) raises:
        game = Game()
        game.play_move(String(self.stones[0].place))
        if name == "Connect6":
            for i in range(1, len(self.stones) - 1, 2):
                var place1 = self.stones[i].place
                var place2 = self.stones[i + 1].place
                game.play_move(String(t"{place1}-{place2}"))
        else:
            for i in range(1, len(self.stones)):
                var place = self.stones[i].place
                game.play_move(String(place))

    def first_black_move(self) raises -> String:
        var x = board_size / 2
        var place = Place(x, x)
        return String(place)

    def first_white_move(self) raises -> String:
        var x = board_size / 2
        var places = List[Place]()
        for j in range(x - 1, x + 2):
            for i in range(x - 1, x + 2):
                if i != x or j != x:
                    places.append(Place(i, j))
        seed()
        shuffle(places)

        if name == "Gomoku":
            return String(places[0])
        else:
            return String(t"{places[0]}-{places[1]}")
