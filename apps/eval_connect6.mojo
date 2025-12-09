from eval import run
from connect6 import Connect6
from mcts import Mcts
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax
from mtdf import Mtdf

comptime Game = Connect6[size=19, max_moves=6, max_places=6, max_plies=100]
# comptime Tree = Mcts[Game, 2]
comptime Tree = AlphaBetaNegamax[Game]
# comptime Tree = PrincipalVariationNegamax[Game]
# comptime Tree = Mtdf[Game]

comptime script = "j10 i9-i10"


fn main() raises:
    run[Tree](script)
