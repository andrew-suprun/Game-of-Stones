from connect6 import Connect6
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax
from principal_variation_negamax_2 import PrincipalVariationNegamax2
from mcts import Mcts
from sim import run

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]


# alias Tree = AlphaBetaNegamax[Game]
# alias Tree = PrincipalVariationNegamax[Game]
# alias Tree = Mcts[Game, 2]

alias Tree1 = PrincipalVariationNegamax[Game]
alias Tree2 = PrincipalVariationNegamax2[Game]


fn main() raises:
    run[Tree1, Tree2]("pvs1", 500, "pvs2", 500, openings())


fn openings() -> List[List[String]]:
    return [
        ["j10", "h8-h11", "l10-i9", "l12-k10"],
        ["j10", "h8-l8", "l11-i12", "h11-j12"],
        ["j10", "h9-i11", "l10-l11", "h11-k11"],
        ["j10", "h9-k8", "i10-j9", "l8-j8"],
        ["j10", "h9-l8", "h8-l9", "k10-j12"],
        ["j10", "h10-h8", "i10-i9", "k8-i8"],
        ["j10", "h10-i12", "i10-l9", "j9-j8"],
        ["j10", "h10-i8", "j8-k10", "k8-l10"],
        ["j10", "h10-j11", "h8-l9", "k12-j8"],
        ["j10", "h11-j12", "i10-l8", "k10-k9"],
        ["j10", "h11-k12", "k8-k11", "k10-k9"],
        ["j10", "h12-h10", "i11-i12", "k11-j9"],
        ["j10", "h12-l11", "j9-l8", "j12-l10"],
        ["j10", "i9-h12", "h11-h10", "i10-j12"],
        ["j10", "i9-j8", "k12-k9", "h12-k8"],
        ["j10", "i9-l8", "k9-k12", "k8-l10"],
        ["j10", "i10-h10", "i9-i12", "l12-k8"],
        ["j10", "i10-h11", "h9-k8", "l12-k9"],
        ["j10", "i10-k9", "h12-l10", "h8-j11"],
        ["j10", "i11-h12", "l9-h11", "k8-l11"],
        ["j10", "i11-j9", "j8-k12", "l10-k11"],
        ["j10", "i11-k12", "k11-i9", "l12-i8"],
        ["j10", "i11-l9", "l12-h11", "h8-k8"],
        ["j10", "i12-j11", "j8-h12", "l10-l8"],
        ["j10", "j8-i10", "j9-l8", "j12-h9"],
        ["j10", "j8-i11", "j12-h10", "i12-j11"],
        ["j10", "j8-i12", "j9-l11", "i9-h12"],
        ["j10", "j8-i8", "k9-j9", "k10-h10"],
        ["j10", "j8-k10", "k11-i11", "h9-h8"],
        ["j10", "j9-k9", "h9-k10", "j8-j12"],
        ["j10", "j11-i10", "l11-k10", "l9-k9"],
        ["j10", "j11-l12", "i9-k11", "h11-h9"],
        ["j10", "j11-l9", "i9-k10", "l10-j8"],
        ["j10", "j12-h11", "k9-i8", "j9-i11"],
        ["j10", "j12-i11", "l11-l9", "k12-h9"],
        ["j10", "j12-l9", "h9-i11", "h8-k11"],
        ["j10", "k8-j9", "l11-h8", "i9-l10"],
        ["j10", "k8-l11", "k11-h12", "k12-j12"],
        ["j10", "k9-h8", "k12-l12", "k11-k8"],
        ["j10", "k9-i11", "i12-l10", "i9-l8"],
        ["j10", "k9-i11", "j12-l9", "l12-l10"],
        ["j10", "k9-j11", "l10-h10", "k11-l9"],
        ["j10", "k9-j9", "l11-i9", "h10-l12"],
        ["j10", "k9-k8", "i11-l9", "l12-h11"],
        ["j10", "k10-i8", "k9-k11", "i11-i9"],
        ["j10", "k11-h12", "k8-i8", "l8-j12"],
        ["j10", "k11-l11", "i12-i9", "l12-l10"],
        ["j10", "k12-h8", "h12-i10", "i11-k10"],
        ["j10", "l9-h11", "j9-l11", "l10-k12"],
        ["j10", "l9-i10", "h11-k8", "k9-j8"],
        ["j10", "l9-k11", "i8-i12", "l12-h8"],
        ["j10", "l9-l12", "i12-j12", "l11-h10"],
        ["j10", "l10-i11", "h10-j11", "h8-l12"],
        ["j10", "l11-j8", "k10-i8", "h12-i10"],
        ["j10", "l11-l8", "i8-l9", "j9-k10"],
        ["j10", "l12-h10", "l8-j12", "h9-j9"],
        ["j10", "l12-h11", "h10-i8", "i12-j12"],
        ["j10", "l12-h9", "l8-i9", "k12-i8"],
        ["j10", "l12-j11", "k10-k8", "h12-h11"],
        ["j10", "l12-k12", "l10-h10", "i9-k11"],
    ]
