from utils.numerics import inf
from game import Score
from board import Board, first

alias win_stones = 6
alias values = List[Score](0, 1, 5, 25, 125, 625, inf[DType.float32]())

fn main() raises:
    var moves_str: String = "j10 i10-i9 i11-l8 j8-k9 k7-i7 m9-j9"
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