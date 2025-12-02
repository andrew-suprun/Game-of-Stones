from eval import run
from connect6 import Connect6
from mcts import Mcts
from principal_variation_negamax_2 import PrincipalVariationNegamax2
from alpha_beta_negamax import AlphaBetaNegamax

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
# alias Tree1 = Mcts[Game, 2]
# alias Tree2 = AlphaBetaNegamax[Game]
alias Tree2 = PrincipalVariationNegamax2[Game]

alias script = "j10 h8-l8 l11-i12 h11-j12 h13-i14 h7-h10 h9-i11 i10-i13 f15-g14 e16-k10 f11-g12"
# alias script = "j10 h8-l8 l11-i12 h11-j12 h13-i14 h7-h10 h9-i11 i10-i13 f15-g14 e16-k10 f11-g12 e10-f10"


fn main() raises:
    # print("--- MCTS ---")
    # run[Tree1](script)
    # print()
    print("--- PVS ---")
    run[Tree2](script)
