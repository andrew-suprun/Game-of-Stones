from utils.numerics import inf
from game import Score
from board import Board, first

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625, inf[DType.float32]())

fn main() raises:
    var moves_str: String = "j10 i9-i10 i7-j11 i13"
    var moves = moves_str.split(" ")
    var board = Board[values, 19, win_stones, 8]()

    var turn = first
    for move in moves:
        var places = move.split("-")
        for place in places:
            board.place_stone(place, turn)
            print(place, board.board_value(values))
            print(board)
            print(board.str_scores())
        turn = 1 - turn