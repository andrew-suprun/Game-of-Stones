import random

from board import Place
from connect6 import Connect6
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax
from mcts import Mcts
from sim import run

comptime Game1 = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]
comptime Game2 = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]


# comptime Tree1 = Mcts[Game1, 2]
comptime Tree1 = PrincipalVariationNegamax[Game1]
comptime Tree2 = PrincipalVariationNegamax[Game2]

comptime seed = 7


fn main() raises:
    run[Tree1, Tree2]("a", 100, "b", 200, openings())


fn openings() -> List[List[String]]:
    return [
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
        ['j10', 'l8-i9', 'l12-l9', 'i11-k12'],
    ]
# fn openings() -> List[List[String]]:
#     random.seed(seed)
#     var result = List[List[String]]()
#     var places = List[String]()
#     for j in range(Game1.size / 2 - 2, Game1.size / 2 + 3):
#         for i in range(Game1.size / 2 - 2, Game1.size / 2 + 3):
#             if i != Game1.size / 2 or j != Game1.size / 2:
#                 places.append(String(Place(Int8(i), Int8(j))))
#     for _ in range(100):
#         random.shuffle(places)
#         moves = [String(Place(Int8(Game1.size / 2), Int8(Game1.size / 2)))]
#         moves.append(String(places[0]) + "-" + String(places[1]))
#         moves.append(String(places[2]) + "-" + String(places[3]))
#         moves.append(String(places[4]) + "-" + String(places[5]))
#         result.append(moves^)
#     return result^