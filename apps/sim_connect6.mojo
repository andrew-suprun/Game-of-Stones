import random

from score import draw
from board import Place
from connect6 import Connect6
from negamax import Negamax
from mcts import Mcts
from sim import run

alias Game = Connect6[max_places=15]
alias Tree1 = Negamax[Game, 20]
alias Tree2 = Mcts[Game, 20, 5]


fn main() raises:
    run[Tree1, Tree2]("Negamax", "Mcts", openings())


fn openings() -> List[List[String]]:
    var result = List[List[String]]()
    var places = List[String]()
    for j in range(7, 12):
        for i in range(7, 12):
            if i != 9 or j != 9:
                places.append(String(Place(Int8(i), Int8(j))))
    for _ in range(100):
        random.shuffle(places)
        moves = List("j10")
        moves.append(String(places[0]) + "-" + String(places[1]))
        moves.append(String(places[2]) + "-" + String(places[3]))
        moves.append(String(places[4]) + "-" + String(places[5]))
        result.append(moves)
    return result
