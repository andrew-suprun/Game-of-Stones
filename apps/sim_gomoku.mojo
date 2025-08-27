import random

from board import Place, size
from gomoku import Gomoku
from mcts import Mcts
from negamax import Negamax
from sim import run

alias Game = Gomoku[max_places=15]
alias Tree1 = Negamax[Game]
alias Tree2 = Mcts[Game, 6]


fn main() raises:
    print("Gomoku: XF", Tree2.c)
    run[Tree1, Tree2]("Negamax", "Mcts", openings())
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
        moves = List(String(Place(Int8(size / 2), Int8(size / 2))))
        moves.append(String(places[0]))
        moves.append(String(places[1]))
        moves.append(String(places[2]))
        moves.append(String(places[3]))
        moves.append(String(places[4]))
        result.append(moves)
    return result
