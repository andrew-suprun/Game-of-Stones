from eval import run
from gomoku import Gomoku
from connect6 import Connect6
from mcts import Mcts
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax

comptime Game = Connect6[size=19, max_moves=26, max_places=20, max_plies=100]
# comptime Game = Gomoku[size=19, max_places=16, max_plies=100]

# comptime Tree = Mcts[Game, 0.35]
comptime Tree = AlphaBetaNegamax[Game]
# comptime Tree = PrincipalVariationNegamax[Game]

comptime script = (
    "j10 j11-l10 i10-h10 j9-i8 h12-k8 k10-l11 h7-n13 l8-l9 l7-l12 k11-m11 h11-n11 h9-k9 e10-i9 g10-m9 k7-n9"
)


def main() raises:
    run[Tree](script)
