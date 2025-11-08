from game_of_stones import game_of_stones
from connect6 import Connect6
from gomoku import Gomoku
from negamax import Search, Negamax
from negamax.basic import Basic
from negamax.alpha_beta import AlphaBeta
from negamax.alpha_beta_memory import AlphaBetaMemory
from negamax.principal_variation import PrincipalVariation
from negamax.principal_variation_memory import PrincipalVariationMemory


alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
# alias Game = Gomoku[size=19, max_places=20, max_plies=100]

# alias Tree = Search[Basic[Game]]
# alias Tree = Search[AlphaBeta[Game]]
# alias Tree = Search[AlphaBetaMemory[Game]]
# alias Tree = Search[PrincipalVariation[Game]]
alias Tree = Search[PrincipalVariationMemory[Game]]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6-Negamax", Tree, Game, stones_per_move=2]()
