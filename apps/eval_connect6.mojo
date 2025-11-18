from eval import run
from connect6 import Connect6
from mcts import Mcts
from principal_variation_negamax import PrincipalVariationNegamax
from alpha_beta_negamax import AlphaBetaNegamax

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
alias Tree1 = Mcts[Game, 2]
alias Tree2 = AlphaBetaNegamax[Game]
# alias Tree2 = PrincipalVariationNegamax[Game]

alias script = "j10 i9-j8 k12-k9 h12-k8 h10-i8 i10-j9 h11-i11 j7-l7 l11-m6 l9-m10"
# alias script = "j10 i9-j8 k12-k9 h12-k8 h10-i8 i10-j9 h11-i11 j7-l7 l11-m6 l9-m10 i6-n11"

fn main() raises:
    print("--- MCTS ---")
    run[Tree1](script)
    print()
    print("--- PVS ---")
    run[Tree2](script)
