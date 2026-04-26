from game_of_stones import game_of_stones
from connect6 import Connect6
from gomoku import Gomoku
from mcts import Mcts

# from alpha_beta_negamax import AlphaBetaNegamax
# from principal_variation_negamax import PrincipalVariationNegamax


comptime board_size = 19

# comptime Game = Gomoku[size=board_size, max_places=16, max_plies=board_size*board_size-board_size]
comptime Game = Connect6[
    size=board_size, max_moves=24, max_places=16, max_plies=(board_size * board_size - board_size) / 2
]

# comptime Tree = Mcts[Game, 6] # for Gomoku
comptime Tree = Mcts[Game, 14]  # for Connect6
# comptime Tree = AlphaBetaNegamax[Game]
# comptime Tree = PrincipalVariationNegamax[Game]


def main() raises:
    game_of_stones[board_size, Tree, Game]()
