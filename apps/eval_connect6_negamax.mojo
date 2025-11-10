from eval import run
from connect6 import Connect6
from principal_variation_negamax import PrincipalVariationNegamax
from alpha_beta_negamax import AlphaBetaNegamax

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
# alias Tree = AlphaBetaNegamax[Game]
alias Tree = PrincipalVariationNegamax[Game]


fn main() raises:
    run[Tree]("j10 i9-i10 k10-l10 g6-g10", "i11-l8")
