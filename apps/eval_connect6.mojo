from eval import run
from connect6 import Connect6
from mcts import Mcts
from principal_variation_negamax import PrincipalVariationNegamax
from alpha_beta_negamax import AlphaBetaNegamax

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
alias Tree1 = Mcts[Game, 2]
# alias Tree2 = AlphaBetaNegamax[Game]
alias Tree2 = PrincipalVariationNegamax[Game]

alias script = "j10 j12-l9 h9-i11 h8-k11 k9-l10 h12-i7 f9-g9 h14-i9 i10-n6 i13-m7 f16-h10 k10-k12 g10-i12 f10-g11 e9-k15 d9-h11"

fn main() raises:
    print("--- MCTS ---")
    run[Tree1](script)
    print()
    print("--- PVS ---")
    run[Tree2](script)
