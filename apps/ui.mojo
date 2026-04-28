from game_of_stones import game_of_stones
from connect6 import Connect6
from gomoku import Gomoku
from mcts import Mcts

# from alpha_beta_negamax import AlphaBetaNegamax
# from principal_variation_negamax import PrincipalVariationNegamax


comptime board_size = 19

# comptime Game = Gomoku[board_size, 16, board_size*board_size-board_size]
comptime Game = Connect6[board_size, 24, 16, (board_size * board_size - board_size) / 2]

# comptime Tree = Mcts[Game, 4] # for Gomoku
comptime Tree = Mcts[Game, 5]  # for Connect6
# comptime Tree = AlphaBetaNegamax[Game]
# comptime Tree = PrincipalVariationNegamax[Game]


def main() raises:
    game_of_stones[board_size, Tree, Game]()
