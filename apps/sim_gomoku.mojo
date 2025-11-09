import random

from board import Place
from gomoku import Gomoku
from mcts import Mcts
from negamax import Negamax
from negamax.principal_variation_memory import PrincipalVariationMemory
from sim import run

alias Game = Gomoku[size=19, max_places=15, max_plies=100]
alias Tree1 = Negamax[PrincipalVariationMemory[Game]]
alias Tree2 = Mcts[Game, 6]
alias seed = 7


fn main() raises:
    print("Gomoku: XF", Tree2.c, "seed", seed)
    run[Tree1, Tree2]("Negamax", "Mcts", openings())
    print()


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
        moves.append(String(places[0]))
        moves.append(String(places[1]))
        moves.append(String(places[2]))
        moves.append(String(places[3]))
        moves.append(String(places[4]))
        result.append(moves^)
    return result^
