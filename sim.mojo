from std.random import seed, shuffle
from std.time import sleep
from std.sys import exit

from engine import Debug
from engine import TTree, MoveValue, Place, first, is_decisive, value_str, first_win, second_win
from engine import Gomoku, Connect6
from engine import Mcts, AlphaBetaNegamax, PrincipalVariationNegamax
from ui import Ui, Stone, Place as UiPlace, Quit, MouseClick

comptime seed_value = 4

comptime black = True
comptime white = False


comptime board_size = 19
comptime time: UInt = 250

# comptime Game = Gomoku[size=board_size, max_plies=100]
comptime Game = Connect6[size=board_size, max_plies=100]

comptime max_moves1 = 16
comptime max_places1 = 12
comptime C1 = 0.25

comptime T1 = AlphaBetaNegamax[Game]
# comptime T1 = PrincipalVariationNegamax[Game]
# comptime T1 = Mcts[Game, C1]

comptime tree_type1 = reflect[T1].base_name()
comptime name1 = String(t"{tree_type1}-{max_moves1}-{max_places1}") if tree_type1 == "Connect6" else String(t"{tree_type1}-{max_moves1}-{C1}")


comptime max_moves2 = 16
comptime max_places2 = 12
comptime C2 = 0.25

# comptime T2 = AlphaBetaNegamax[Game]
# comptime T2 = PrincipalVariationNegamax[Game]
comptime T2 = Mcts[Game, C2]

comptime tree_type2 = reflect[T2].base_name()
comptime name2 = String(t"{tree_type2}-{max_moves2}-{max_places2}") if tree_type2 == "Connect6" else String(t"{tree_type2}-{max_moves2}-{C2}")

comptime game_name = reflect[T1.Game].base_name()


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
            elif winner1 == name2:
                self.second_wins += 1
            else:
                self.draws += 1
            print(t"{n}: {name1} : {name2} - {self.first_wins} : {self.second_wins} ({self.draws})")
            n += 1
            var event = self.ui.wait_event(2000)
            if event.isa[Quit]():
                exit(0)

            var sim2 = SimOpening[T2, T1](self.ui)
            var winner2 = sim2.sim_opening(name2, name1, opening)

            if winner2 == name1:
                self.first_wins += 1
            elif winner2 == name2:
                self.second_wins += 1
            else:
                self.draws += 1

            print(t"{n}: {name1} : {name2} - {self.first_wins} : {self.second_wins} ({self.draws})")
            n += 1
            event = self.ui.wait_event(2000)
            if event.isa[Quit]():
                exit(0)
        print(t"Game: {game_name}: seed: {seed_value}; time {time} msec/move -- {name1} : {name2} - {self.first_wins} : {self.second_wins} ({self.draws})")


struct SimOpening[T1: TTree, T2: TTree]:
    var ui: Ui[board_size]
    var stones: List[Stone]
    var g1: Self.T1.Game
    var g2: Self.T2.Game
    var t1: Self.T1
    var t2: Self.T2
    var first_turn: Bool
    var plies: Int

    def __init__(out self, ui: Ui[board_size]):
        self.ui = ui.copy()
        self.stones = []
        self.g1 = Self.T1.Game()
        self.g2 = Self.T2.Game()
        self.t1 = Self.T1()
        self.t2 = Self.T2()
        self.first_turn = True
        self.plies = 1

    def sim_opening(mut self, name1: String, name2: String, opening: List[String]) raises -> String:
        for move in opening:
            self.play_move(move)

        while True:
            if self.first_turn:
                var pv = self.t1.search(self.g1, max_moves1, time)
                assert len(pv) > 0, t"{game_name}.search() returned no results"
                self.play_move(String(pv[0]))
                if self.g1.decision() == first_win:
                    return name1
                elif self.g1.decision() == second_win:
                    return name2
            else:
                var pv = self.t2.search(self.g2, max_moves2, time)
                assert len(pv) > 0, t"{game_name}.search() returned no results"
                self.play_move(String(pv[0]))
                if self.g2.decision() == first_win:
                    return name2
                elif self.g2.decision() == second_win:
                    return name2

    def play_move(mut self, move: String) raises:
        print(move)
        self.g1.play_move({move})
        self.g2.play_move({move})
        var places = String(move).split("-")
        for place_str in places:
            var place = Place(String(place_str))
            self.stones.append(Stone(UiPlace(Int(place.x), Int(place.y)), self.first_turn, False))
        self.plies += 1
        self.first_turn = not self.first_turn
        for ref stone in self.stones:
            stone.selected = False
        if len(self.stones) >= 2:
            self.stones[len(self.stones) - 1].selected = True
            self.stones[len(self.stones) - 2].selected = True
        self.ui.draw(self.stones)
        var event = self.ui.poll_event()
        if event.isa[Quit]():
            exit(0)


def openings() -> List[List[String]]:
    seed(seed_value)
    var result = List[List[String]]()
    var places = List[String]()
    for j in range(Game.size / 2 - 2, Game.size / 2 + 3):
        for i in range(Game.size / 2 - 2, Game.size / 2 + 3):
            if i != Game.size / 2 or j != Game.size / 2:
                places.append(String(Place(i, j)))
    for _ in range(50):
        shuffle(places)
        moves = [String(Place(Game.size / 2, Game.size / 2))]
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
