from game_of_stones import game_of_stones
from connect6 import Connect6
from gomoku import Gomoku
from mcts import Mcts
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax


# comptime Game = Gomoku[size=19, max_places=20, max_plies=100]
# comptime stones_per_move = 1

comptime Game = Connect6[size=19, max_moves=20, max_places=15, max_plies=100]
comptime stones_per_move = 2

# comptime Tree = Mcts[Game, 8]
# comptime Tree = AlphaBetaNegamax[Game]
comptime Tree = PrincipalVariationNegamax[Game]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6-Negamax", Tree, Game, stones_per_move]()
