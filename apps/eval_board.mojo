from game import Score
from board import Board, first

alias win_stones = 6
alias values = List[Score](0, 1, 5, 25, 125, 625)

fn main() raises:
    var moves_str: String = "j10 i9 g9 h9 k9 i10"
    var moves = moves_str.split(" ")
    var board = Board[values, 19, 6, 20]()

    var turn = first
    for move in moves:
        var places = move.split("-")
        for place in places:
            board.place_stone(place, turn)
        print(move, board)
        print(board.board_value(values))
        turn = 1 - turn