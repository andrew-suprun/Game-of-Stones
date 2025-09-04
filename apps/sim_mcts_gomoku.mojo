import random

from board import Place, size
from connect6 import Connect6
from mcts import Mcts
from gomoku import Gomoku
from sim import run

alias Game = Gomoku[size=19, max_places=20, max_plies=100]
alias Tree1 = Mcts[Game, 6]
alias Tree2 = Mcts[Game, 8]


fn main() raises:
    print("Gomoku")
    run[Tree1, Tree2]("M6", "M8", openings())
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
