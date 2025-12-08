import random

from board import Place
from connect6 import Connect6
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax
from sim import run

comptime size = 19
comptime Game = Connect6[size=size, max_moves=20, max_places=15, max_plies=100]
comptime Tree1 = AlphaBetaNegamax[Game]
comptime Tree2 = PrincipalVariationNegamax[Game]


fn main() raises:
    print("Connect6")
    run[Tree1, Tree2]("AB", 1000, "PV", 1000, openings())
    print()


fn openings() -> List[List[String]]:
    random.seed(5)
    var result = List[List[String]]()
    var places = List[String]()
    for j in range(size / 2 - 2, size / 2 + 3):
        for i in range(size / 2 - 2, size / 2 + 3):
            if i != size / 2 or j != size / 2:
                places.append(String(Place(Int8(i), Int8(j))))
    for _ in range(100):
        random.shuffle(places)
        moves = [String(Place(Int8(size / 2), Int8(size / 2)))]
        moves.append(String(places[0]) + "-" + String(places[1]))
        moves.append(String(places[2]) + "-" + String(places[3]))
        moves.append(String(places[4]) + "-" + String(places[5]))
        result.append(moves^)
    return result^
