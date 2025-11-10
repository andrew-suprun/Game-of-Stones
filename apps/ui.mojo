from game_of_stones import game_of_stones
from connect6 import Connect6
from gomoku import Gomoku
from mcts import Mcts
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax


# alias Game = Gomoku[size=19, max_places=20, max_plies=100]
# alias stones_per_move = 1

alias Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
alias stones_per_move = 2

# alias Tree = Mcts[Game, 8]
# alias Tree = AlphaBetaNegamax[Game]
alias Tree = PrincipalVariationNegamax[Game]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6-Negamax", Tree, Game, stones_per_move]()
