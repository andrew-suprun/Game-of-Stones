from sys import env_get_int

from game_of_stones import game_of_stones
from score import draw
from mcts import Mcts
from gomoku import Gomoku

alias Game = Gomoku[max_places = 15]
alias Tree = Mcts[Game, max_moves = 20, c = 5, no_legal_moves_decision = draw]

fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Gomoku-MCTS", Tree, Game, stones_per_move = 1]()
