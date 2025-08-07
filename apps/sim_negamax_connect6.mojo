from negamax import Negamax
from connect6 import Connect6
from sim import run

alias Game1 = Connect6[19, 15]
alias Tree1 = Negamax[Game1, 20]

alias Game2 = Connect6[19, 15]
alias Tree2 = Negamax[Game2, 20]

fn main() raises: run[Tree1, Tree2]("a", "b")