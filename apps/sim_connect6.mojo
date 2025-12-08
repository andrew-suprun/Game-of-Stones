import random

from board import Place
from connect6 import Connect6
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax
from mcts import Mcts
from sim import run

alias Game = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]


alias Tree1 = Mcts[Game, 2]
# alias Tree = AlphaBetaNegamax[Game]
alias Tree2 = PrincipalVariationNegamax[Game]

alias seed = 7


fn main() raises:
    run[Tree1, Tree2]("mcts", 4000, "pvs", 4000, openings())


fn openings() -> List[List[String]]:
    random.seed(seed)
    var result = List[List[String]]()
    var places = List[String]()
    for j in range(Game.size / 2 - 2, Game.size / 2 + 3):
        for i in range(Game.size / 2 - 2, Game.size / 2 + 3):
            if i != Game.size / 2 or j != Game.size / 2:
                places.append(String(Place(Int8(i), Int8(j))))
    for _ in range(100):
        random.shuffle(places)
        moves = List(String(Place(Int8(Game.size / 2), Int8(Game.size / 2))))
        moves.append(String(places[0]) + "-" + String(places[1]))
        moves.append(String(places[2]) + "-" + String(places[3]))
        moves.append(String(places[4]) + "-" + String(places[5]))
        result.append(moves^)
    return result^