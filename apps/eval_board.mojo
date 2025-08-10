from utils.numerics import inf
from game import Score
from board import Board, Place, first, second

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625, inf[DType.float32]())

fn main() raises:
    var moves_str: String = "j10 h10-h11 i11-k12 i9-i10 " "h12-k9 g13-m7 j8-j9 j7-j13 k10-k11 k7-k13 i7-l10 h6-m11 i13-j12 h14-m9 l11-m12"
    var moves = moves_str.split(" ")
    var board = Board[values, 19, win_stones]()
    var value = Score(0)

    var turn = first
    for move in moves:
        var places = move.split("-")
        var score = Score(0)
        for place_str in places:
            print("----")
            var place = Place(String(place_str))
            if turn == first:
                board_score = board.score(place, first)
                score += board_score
                value += board_score
                print(place, board.score(place, first))
                board.place_stone(String(place), first)
            else:
                board_score = board.score(place, second)
                score -= board_score
                value -= board_score
                print(place, board.score(place, second))
                board.place_stone(String(place), second)
            debug_assert(value == board.board_value(values))
            print(board)
            # print(board.str_scores())
            print("score", score)
            print("board", value)
        
        var opp_value = board.max_score(first) if turn == second else -board.max_score(second)

        print("opp", opp_value)
        print("score+opp", score+opp_value)
        print("board+opp", value + opp_value)

        turn = 1 - turn
