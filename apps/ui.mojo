from game_of_stones import game_of_stones
from connect6 import Connect6
from gomoku import Gomoku
from mcts import Mcts
from negamax import Negamax
from negamax.basic import Basic
from negamax.alpha_beta import AlphaBeta
from negamax.alpha_beta_memory import AlphaBetaMemory
from negamax.principal_variation import PrincipalVariation
from negamax.principal_variation_memory import PrincipalVariationMemory


# alias Game = Gomoku[size=19, max_places=20, max_plies=100]
# alias stones_per_move = 1

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
alias stones_per_move = 2

alias Tree = Mcts[Game, 8]
# alias Tree = Negamax[Basic[Game]]
# alias Tree = Negamax[AlphaBeta[Game]]
# alias Tree = Negamax[AlphaBetaMemory[Game]]
# alias Tree = Negamax[PrincipalVariation[Game]]
# alias Tree = Negamax[PrincipalVariationMemory[Game]]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6-Negamax", Tree, Game, stones_per_move]()
