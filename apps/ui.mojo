from game_of_stones import game_of_stones
from connect6 import Connect6
from gomoku import Gomoku
from mcts import Mcts
from alpha_beta_negamax import AlphaBetaNegamax
from principal_variation_negamax import PrincipalVariationNegamax


comptime Game = Gomoku[size=19, max_places=16, max_plies=300]
comptime name = "Gomoku"
comptime stones_per_move = 1

# comptime Game = Connect6[size=19, max_moves=16, max_places=12, max_plies=150]
# comptime name = "Connect6"
# comptime stones_per_move = 2

# comptime Tree = Mcts[Game, 4]
# comptime Tree = AlphaBetaNegamax[Game]
comptime Tree = PrincipalVariationNegamax[Game]


fn main() raises:
    game_of_stones[name, Tree, Game, stones_per_move]()
