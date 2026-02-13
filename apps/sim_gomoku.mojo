import random

from board import Place
from gomoku import Gomoku
from mcts import Mcts
from principal_variation_negamax import PrincipalVariationNegamax
from sim import run

comptime Game1 = Gomoku[size=19, max_places=16, max_plies=100]
comptime Game2 = Gomoku[size=19, max_places=16, max_plies=100]

# comptime Tree1 = PrincipalVariationNegamax[Game1]
# comptime Tree2 = PrincipalVariationNegamax[Game2]

comptime Tree1 = Mcts[Game1, 4]
comptime Tree2 = Mcts[Game2, 5]

comptime seed = 7


fn main() raises:
    run[Tree1, Tree2]("4", 250, "5", 250, openings())


fn openings() -> List[List[String]]:
    random.seed(seed)
    var result = List[List[String]]()
    var places = List[String]()
    for j in range(Game1.size / 2 - 2, Game1.size / 2 + 3):
        for i in range(Game1.size / 2 - 2, Game1.size / 2 + 3):
            if i != Game1.size / 2 or j != Game1.size / 2:
                places.append(String(Place(i, j)))
    for _ in range(100):
        random.shuffle(places)
        moves = [String(Place(Game1.size / 2, Game1.size / 2))]
        moves.append(String(places[0]))
        moves.append(String(places[1]))
        moves.append(String(places[2]))
        moves.append(String(places[3]))
        moves.append(String(places[4]))
        result.append(moves^)
    return result^
