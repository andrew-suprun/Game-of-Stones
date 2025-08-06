from sys import env_get_int

from negamax import Negamax
from connect6 import Connect6, Move
from sim import run

alias m1 = env_get_int["M1", 20]()
alias p1 = env_get_int["P1", 15]()
alias m2 = env_get_int["M2", 30]()
alias p2 = env_get_int["P2", 15]()

alias Game1 = Connect6[19, p1]
alias Game2 = Connect6[19, p2]
alias Tree1 = Negamax[Game1, m1]
alias Tree2 = Negamax[Game2, m1]

fn main() raises:
    run[Tree1, Tree2](String(m1)+"-"+String(p1), String(m2)+"-"+String(p2))