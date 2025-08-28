from eval import run
from connect6 import Connect6
from mcts import Mcts

fn main() raises:
    run[Mcts[Connect6[max_moves=20, max_places=15], 40]](
        "d4 c3-d2 e6-e3 b6-e2", 
        "a4-c2 b5-e4 b1-f1 b7-d5 e1-g1 d1-f5 a5-a6 a2-f7 c5-g2 b2-c7 f2-f3 b3-b4")
