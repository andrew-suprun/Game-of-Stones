from traits import Score
from board import Board, Place, first, second

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625, Float32.MAX)


fn main() raises:
    var moves_str = "j10 j9-j12 i12-k12 h12-h9 i9-k11 h8-i8 h10-k10 j8-k8 g10-i10 l8-m8"
    var moves = moves_str.split(" ")
    var board = Board[19, values, win_stones]()
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
                board.place_stone(place, first)
            else:
                board_score = board.score(place, second)
                score -= board_score
                value -= board_score
                print(place, board.score(place, second))
                board.place_stone(place, second)
            debug_assert(value == board.board_value(materialize[values]()))
            print(board)
            # print(board.str_scores())
            print("score", score)
            print("board", value)

        var opp_value = board.max_score(first) if turn == second else -board.max_score(second)

        print("opp", opp_value)
        print("score+opp", score + opp_value)
        print("board+opp", value + opp_value)

        turn = 1 - turn
