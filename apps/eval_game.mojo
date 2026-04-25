from eval import run
from gomoku import Gomoku
from connect6 import Connect6
from mcts import Mcts
from alpha_beta_negamax import AlphaBetaNegamax
# from principal_variation_negamax import PrincipalVariationNegamax

comptime Game = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]
# comptime Game = Gomoku[size=19, max_places=16, max_plies=100]

# comptime Tree = Mcts[Game, 16]
comptime Tree = AlphaBetaNegamax[Game]
# comptime Tree = PrincipalVariationNegamax[Game]

comptime script = "j10 k9-k11 j9-i9 i11-k12 j11-j12 j7-j13 k10-m10 i8-l10 m11-m12"


def main() raises:
    print("Connect6: max_moves:", Game.max_moves, "max_places:", Game.max_places)
    run[Tree](script)
