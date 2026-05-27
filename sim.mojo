from std.random import seed, shuffle
from std.time import sleep
from std.sys import exit

from engine import TTree, Score, MoveScore, Place, first
from engine import Gomoku, Connect6
from engine import Mcts, AlphaBetaNegamax
from ui import Ui, Stone, Place as UiPlace, Quit, MouseClick, black

comptime seed_value = 9

comptime board_size = 19
comptime time: UInt = 500


comptime max_moves1 = 26
comptime max_places1 = 20
comptime C1 = Score(0.25)

comptime max_moves2 = 22
comptime max_places2 = 20
comptime C2 = Score(0.4)

# comptime Game1 = Gomoku[size=board_size, max_moves=max_moves1]
# comptime Game2 = Gomoku[size=board_size, max_moves=max_moves2]
comptime Game1 = Connect6[size=board_size, max_moves=max_moves1, max_places=max_places1]
comptime Game2 = Connect6[size=board_size, max_moves=max_moves2, max_places=max_places2]


comptime T1 = AlphaBetaNegamax[Game1]
# comptime T1 = PrincipalVariationNegamax[Game1]
# comptime T1 = Mcts[Game1, C1]

comptime game_name = reflect[Game1].base_name()
comptime tree_type1 = reflect[T1].base_name()
comptime game_name1 = String(t"{tree_type1}-{max_moves1}-{max_places1}") if game_name == "Connect6" else String(t"{tree_type1}-{max_moves1}")
comptime name1 = game_name1 if tree_type1 != "Mcts" else String(t"{game_name1}-{C1}")


# comptime T2 = ZeroSearch[Game1]
# comptime T2 = AlphaBetaNegamax[Game2]
# comptime T2 = PrincipalVariationNegamax[Game2]
comptime T2 = Mcts[Game2, C2]

comptime tree_type2 = reflect[T2].base_name()
comptime game_name2 = String(t"{tree_type2}-{max_moves2}-{max_places2}") if game_name == "Connect6" else String(t"{tree_type2}-{max_moves2}")
comptime name2 = game_name2 if tree_type2 != "Mcts" else String(t"{game_name2}-{C2}")


struct Sim:
    var first_wins: Int
    var second_wins: Int
    var draws: Int
    var ui: Ui[board_size]

    def __init__(out self) raises:
        self.first_wins = 0
        self.second_wins = 0
        self.draws = 0
        self.ui = {game_name}

    def run(mut self) raises:
        print(t"Game: {game_name}: {name1} vs. {name2}; seed: {seed_value}; time {time} msec/move")
        var n = 1
        for opening in openings():
            var sim1 = SimOpening[T1, T2](self.ui)
            var winner1 = sim1.sim_opening(name1, name2, opening)
            if winner1 == name1:
                self.first_wins += 1
                print(t"\n{n}: winner {name1} (black) {self.first_wins}* : {self.second_wins} ({self.draws})")
            elif winner1 == name2:
                self.second_wins += 1
                print(t"\n{n}: winner {name2} (white) {self.first_wins} : {self.second_wins}* ({self.draws})")
            else:
                self.draws += 1
                print(t"\n{n}: draw {self.first_wins} : {self.second_wins} ({self.draws}*)")
            n += 1
            var event = self.ui.wait_event(1500)
            if event.isa[Quit]():
                exit(0)
            print()

            var sim2 = SimOpening[T2, T1](self.ui)
            var winner2 = sim2.sim_opening(name2, name1, opening)

            if winner2 == name1:
                self.first_wins += 1
                print(t"\n{n}: winner {name1} (white) {self.first_wins}* : {self.second_wins} ({self.draws})")
            elif winner2 == name2:
                self.second_wins += 1
                print(t"\n{n}: winner {name2} (black) {self.first_wins} : {self.second_wins}* ({self.draws})")
            else:
                self.draws += 1
                print(t"\n{n}: draw {self.first_wins} : {self.second_wins} ({self.draws}*)")

            n += 1
            event = self.ui.wait_event(1500)
            if event.isa[Quit]():
                exit(0)
            print()
        print(t"Game: {game_name}: seed: {seed_value}; time {time} msec/move -- {name1} : {name2} - {self.first_wins} : {self.second_wins} ({self.draws})")


struct SimOpening[T1: TTree, T2: TTree]:
    var ui: Ui[board_size]
    var stones: List[Stone]
    var g1: Self.T1.Game
    var g2: Self.T2.Game
    var t1: Self.T1
    var t2: Self.T2
    var color: Int
    var plies: Int

    def __init__(out self, ui: Ui[board_size]):
        self.ui = ui.copy()
        self.stones = []
        self.g1 = Self.T1.Game()
        self.g2 = Self.T2.Game()
        self.t1 = Self.T1()
        self.t2 = Self.T2()
        self.color = black
        self.plies = 1

    def sim_opening(mut self, name_black: String, name_white: String, opening: List[String]) raises -> String:
        print("open: ", end="")
        for move in opening:
            self.play_move(move)

        print("\nplay: ", end="")
        while self.plies < 100:
            if self.color == black:
                var pv = self.t1.search(self.g1, time)
                assert len(pv) > 0, t"{game_name}.search() returned no results"
                self.play_move(String(pv[0]))
                if self.g1.score().is_win():
                    return name_black
                elif self.g1.score().is_loss():
                    assert False
            else:
                var pv = self.t2.search(self.g2, time)
                assert len(pv) > 0, t"{game_name}.search() returned no results"
                self.play_move(String(pv[0]))
                if self.g2.score().is_win():
                    assert False
                elif self.g2.score().is_loss():
                    return name_white
        return "draw"

    def play_move(mut self, move: String) raises:
        print(t"{move} ", end="")
        self.g1.play_move({move})
        self.g2.play_move({move})
        var places = String(move).split("-")
        for place_str in places:
            var place = Place(String(place_str))
            self.stones.append(Stone(place, self.color, False))
        self.plies += 1
        self.color = 1 - self.color
        for ref stone in self.stones:
            stone.selected = False
        self.stones[len(self.stones) - 1].selected = True
        if game_name == "Connect6" and len(self.stones) >= 2:
            self.stones[len(self.stones) - 2].selected = True
        self.ui.draw(self.stones)
        var event = self.ui.poll_event()
        if event.isa[Quit]():
            exit(0)


def openings() -> List[List[String]]:
    seed(seed_value)
    var result = List[List[String]]()
    var places = List[String]()
    for j in range(Game1.size / 2 - 2, Game1.size / 2 + 3):
        for i in range(Game1.size / 2 - 2, Game1.size / 2 + 3):
            if i != Game1.size / 2 or j != Game1.size / 2:
                places.append(String(Place(i, j)))
    for _ in range(50):
        shuffle(places)
        moves = [String(Place(Game1.size / 2, Game1.size / 2))]
        if game_name == "Connect6":
            for i in range(0, 4):
                moves.append(String(t"{places[i]}-{places[i+4]}"))
        else:
            for i in range(0, 6):
                moves.append(places[i])
        result.append(moves^)
    return result^


def main() raises:
    var ui = Sim()
    ui.run()
