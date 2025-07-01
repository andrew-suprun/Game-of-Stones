from utils.numerics import inf
from game import Score
from board import Board, first

alias win_stones = 5
alias values = List[Score](0, 1, 5, 25, 125, inf[DType.float32]())

fn main() raises:
    var moves_str: String = "j10 i9 g9 h9 i11 h10 g11 h11 h12 k9 f10 l9"
    var moves = moves_str.split(" ")
    var board = Board[values, 19, win_stones, 8]()

    var turn = first
    for move in moves:
        var places = move.split("-")
        for place in places:
            board.place_stone(place, turn)
            print(place, board.board_value(values))
            print(board)
        turn = 1 - turn