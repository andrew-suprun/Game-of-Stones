from eval import run
from gomoku import Gomoku
from mcts import Mcts


fn main() raises:
    run[Mcts[Gomoku[size=19, max_places=20, max_plies=100], c=6]](
        "d4 d6 f3 b3 c5 b2", "c4 e4 b5 e3 e5 d5 c3 c2 f1 e2 d2 f6 e1 c6 g6 a5 e6 f2 b1 c1 a2 g1 g4 d7 g5 c7 g3 b6 g2"
    )
