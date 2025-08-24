from game_of_stones import game_of_stones
from score import draw
from connect6 import Connect6
from mcts import Mcts

alias Game = Connect6[max_moves=20, max_places=15]
alias Tree = Mcts[Game, c=5]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Connect6-MCTS", Tree, Game, stones_per_move=2]()
