from eval import run
from connect6 import Connect6
from mcts import Mcts
from principal_variation_negamax_2 import PrincipalVariationNegamax2
from alpha_beta_negamax import AlphaBetaNegamax

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
# alias Tree1 = Mcts[Game, 2]
# alias Tree2 = AlphaBetaNegamax[Game]
alias Tree2 = PrincipalVariationNegamax2[Game]

alias script = "j10 h10-i12 i10-l9 j9-j8"


fn main() raises:
    # print("--- MCTS ---")
    # run[Tree1](script)
    # print()
    print("--- PVS ---")
    run[Tree2](script)
