import random
from time import perf_counter_ns

from negamax import Negamax
from score import draw
from connect6 import Connect6
from board import Place
from sim import run

alias Game1 = Connect6[values = List[Float32](0, 1, 6, 30, 120, 360), max_places=15]
alias Tree1 = Negamax[Game1, 20, draw]

alias Game2 = Connect6[values = List[Float32](0, 1, 5, 25, 125, 625), max_places=15]
alias Tree2 = Negamax[Game2, 20, draw]


fn main() raises:
    run[Tree1, Tree2]("360", "625", openings())


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
