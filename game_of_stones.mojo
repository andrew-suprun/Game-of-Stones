from std.time import perf_counter_ns
from std.random import seed, shuffle

from engine import Connect6, Gomoku
from engine import Mcts, AlphaBetaNegamax, PrincipalVariationNegamax
from engine import MoveValue, Place, is_decisive
from ui import Ui, Event, Stone, Place as UiPlace, EnterKey, LeftKey, RightKey, Quit, MouseClick, black, white

comptime duration = 1000

comptime board_size = 19

comptime GomokuGame = Gomoku[board_size, 22]
comptime Connect6Game = Connect6[board_size, 26, 20]

# comptime Game = GomokuGame
comptime Game = Connect6Game

# comptime Tree = Mcts[Game, 0.25] # Gomoku
comptime Tree = Mcts[Game, 0.35]  # Connect6
# comptime Tree = AlphaBetaNegamax[Game]
# comptime Tree = PrincipalVariationNegamax[Game]


def main() raises:
    var done = False
    while not done:
        var game = GameOfStones()
        done = game.run()


struct GameOfStones:
    comptime Move = Game.Move
    var name: String
    var ui: Ui[board_size]
    var stones: List[Stone]
    var undo_stones: List[Stone]
    var game: Game
    var tree: Tree
    var turn: Int
    var human_stones: Int
    var search_complete: Bool
    var game_complete: Bool
    var game_complete_confirmed: Bool
    var app_complete: Bool

    def __init__(out self) raises:
        self.name = reflect[Game].base_name()
        self.ui = Ui[board_size](self.name)
        self.stones = List[Stone]()
        self.undo_stones = List[Stone]()
        self.game = Game()
        self.tree = Tree()
        self.turn = black
        self.human_stones = white
        self.search_complete = False
        self.game_complete = False
        self.game_complete_confirmed = False
        self.app_complete = False

    def run(mut self) raises -> Bool:
        self.play_move(self.first_black_move())

        while not self.app_complete and not self.game_complete_confirmed:
            print(t">> next move: turn: {self.turn}, human: {self.human_stones}")
            if self.turn == self.human_stones:
                self.human_move()
            else:
                self.engine_move()
        return self.app_complete

    def play_move(mut self, move: String) raises:
        var places = move.split("-")
        for place_str in places:
            place = Place(String(place_str))
            self.stones.append(Stone(UiPlace(Int(place.x), Int(place.y)), self.turn, True))
        self.game.play_move(Game.Move(move))
        print(self.game.board)
        self.turn = 1 - self.turn
        self.search_complete = is_decisive(self.game.value())
        self.select_last_move()

    def select_last_move(mut self) raises:
        for ref stone in self.stones:
            stone.selected = False

        self.stones[len(self.stones) - 1].selected = True
        if len(self.stones) > 2 and self.stones[len(self.stones) - 1].color == self.stones[len(self.stones) - 2].color:
            self.stones[len(self.stones) - 2].selected = True

        for i in range(len(self.stones) - 1, -1, -1):
            ref stone = self.stones[i]
            if stone.color == self.turn:
                break
            stone.selected = True
        self.ui.draw(self.stones)

    def human_move(mut self) raises:
        print(t"human move: {self.human_stones} turn: {self.turn}")
        while True:
            var event = self.ui.wait_event()
            if event.isa[Quit]():
                self.app_complete = True
                return

            elif event.isa[LeftKey]():
                self.undo()
                self.ui.draw(self.stones)
                return

            elif event.isa[RightKey]():
                self.redo()
                self.ui.draw(self.stones)
                return

            elif event.isa[EnterKey]():
                self.commit_move()
                self.ui.draw(self.stones)
                return

            elif event.isa[MouseClick]():
                self.handle_mouse(event)
                self.ui.draw(self.stones)
                return

    def undo(mut self) raises:
        if len(self.stones) == 1:
            return

        var color = self.stones[len(self.stones) - 1].color
        while color == self.stones[len(self.stones) - 1].color:
            self.undo_stones.append(self.stones.pop())

        if color != self.human_stones:
            print("undo ", end="")

            self.game_complete = False
            self.game = Game()
            var place = Place(self.stones[0].place.x, self.stones[0].place.y)
            self.game.play_move(String(place))
            if self.name == "Connect6":
                for i in range(1, len(self.stones) - 1, 2):
                    var place1 = Place(self.stones[i].place.x, self.stones[i].place.y)
                    var place2 = Place(self.stones[i + 1].place.x, self.stones[i + 1].place.y)
                    self.game.play_move(String(t"{place1}-{place2}"))
            else:
                for i in range(1, len(self.stones)):
                    var place = Place(self.stones[i].place.x, self.stones[i].place.y)
                    self.game.play_move(String(t"{place}"))
            self.human_stones = 1 - self.human_stones
            self.turn = 1 - self.turn
            self.select_last_move()

    def redo(mut self) raises:
        print(t"---- redo turn: {self.turn}; human: {self.human_stones}; undo stones: {len(self.undo_stones)}")
        if not self.undo_stones:
            return

        print("redo ", end="")
        if self.name == "Connect6" and len(self.undo_stones) >= 2:
            var stone1 = self.undo_stones.pop()
            var place1 = Place(stone1.place.x, stone1.place.y)
            self.stones.append(stone1)
            var stone2 = self.undo_stones.pop()
            var place2 = Place(stone2.place.x, stone2.place.y)
            self.stones.append(stone2)
            self.game.play_move(String(t"{place1}-{place2}"))

        elif self.name == "Gomoku" and self.undo_stones:
            var stone = self.undo_stones.pop()
            self.stones.append(stone)
            self.game.play_move(String(t"{stone.place}"))

        self.human_stones = 1 - self.human_stones
        self.turn = 1 - self.turn
        self.select_last_move()

    def commit_move(mut self) raises:
        print(t"commit_move: stones: {len(self.stones)}")
        if self.game_complete:
            self.game_complete_confirmed = True
            print("r0")
            return

        var idx = len(self.stones) - 1
        var n_selected = 0
        while idx >= 0 and self.stones[idx].color == self.human_stones:
            idx -= 1
            n_selected += 1

        if n_selected == 0:
            self.human_stones = 1 - self.human_stones
            print("r1")
            return

        if self.name == "Connect6" and n_selected == 2:
            var place1 = Place(self.stones[idx + 1].place.x, self.stones[idx + 1].place.y)
            var place2 = Place(self.stones[idx + 2].place.x, self.stones[idx + 2].place.y)
            var move = String(t"{place1}-{place2}")
            print(t"{move} ")
            self.play_move(move)
            print("r2")
            return

        if self.name == "Gomoku" and n_selected == 1:
            var place = Place(self.stones[idx + 1].place.x, self.stones[idx + 1].place.y)
            var move = String(t"{place}")
            print(t"{move} ")
            self.play_move(move)
            print("r3")
            return

    def handle_mouse(mut self, event: Event) raises:
        if self.game_complete:
            return
        ref click_event = event[MouseClick]
        for i, stone in enumerate(self.stones):
            if click_event.place == stone.place:
                if click_event.place == stone.place and stone.selected and stone.color == self.human_stones:
                    _ = self.stones.pop(i)
                break
        else:
            var stone = Stone(click_event.place, self.human_stones, True)
            if self.name == "Connect6" and len(self.stones) > 2 and self.stones[len(self.stones) - 2].color == self.human_stones:
                _ = self.stones.pop(len(self.stones) - 2)
            elif self.name == "Gomoku" and len(self.stones) > 1 and self.stones[len(self.stones) - 1].color == self.human_stones:
                _ = self.stones.pop()

            self.stones.append(stone)

    def engine_move(mut self) raises:
        print(t"engine move: {1-self.human_stones} turn {self.turn}")
        if self.app_complete or self.game_complete:
            return

        if len(self.stones) == 1:
            var move = self.first_white_move()
            self.play_move(move)
            return

        var pv = self.tree.search(self.game, duration)
        self.play_move(String(pv[0]))
        if is_decisive(self.game.value()):
            self.game_complete = True

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

        if self.name == "Gomoku":
            return String(places[0])
        else:
            return String(t"{places[0]}-{places[1]}")
