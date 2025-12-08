from eval import run
from connect6 import Connect6
from mcts import Mcts
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax
from mtdf import Mtdf

alias Game = Connect6[size=19, max_moves=6, max_places=6, max_plies=100]
# alias Tree = Mcts[Game, 2]
# alias Tree = AlphaBetaNegamax[Game]
# alias Tree = PrincipalVariationNegamax[Game]
alias Tree = Mtdf[Game]

alias script = "j10 h10-i12 i10-l9 j9-j8"


fn main() raises:
    run[Tree](script)
