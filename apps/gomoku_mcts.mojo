from game_of_stones import game_of_stones
from score import draw
from gomoku import Gomoku
from mcts import Mcts

alias Game = Gomoku[max_places=15]
alias Tree = Mcts[Game, c=10]


fn main() raises:
    var done = False
    while not done:
        done = game_of_stones["Gomoku-MCTS", Tree, Game, stones_per_move=1]()
