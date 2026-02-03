from eval import run
from connect6 import Connect6, State
# from mcts import Mcts
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax
# from mtdf import Mtdf

comptime Game = Connect6[size=19, max_moves=16, max_places=12, max_plies=100]

# comptime Tree = Mcts[Game, 2]
comptime Tree = AlphaBetaNegamax[Game]
# comptime Tree = PrincipalVariationNegamax[Game]
# comptime Tree = Mtdf[Game]

comptime script = "j10 i9-j11"
# comptime script = "j10 i10-j9 i9-k11 g12-h11 f13-k8 h8-h12 h10-k10 f12-i12 e12-k12 j13-k9 k14-l12 k15-m13 g14-h15 d11-i16 j14-l14 e8-i14"
# comptime script = "j10 i9-i11 h10-i10 g10-m10 h9-h11 g12-h12 g8-h7 f7-h8 i6-j5 f9-l3 j7-j9 f6-j8 j11-l7 k8-k12 k7-m7 i7-n7"
# comptime script = "j10 i9-i11 h10-i10 g10-k10 j9-j11 h9-j8 g12-h11 f13-l7 f11-h12 h15-j12 d9-e10"


fn main() raises:
    print("Connect6: max_moves:", Game.max_moves, "max_places:", Game.max_places)
    run[Tree](script)
