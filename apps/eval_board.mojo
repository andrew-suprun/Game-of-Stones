from utils.numerics import inf
from game import Score
from board import Board, Place, first, second

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625, inf[DType.float32]())

fn main() raises:
    var moves_str: String = "j10 i9-i10 i11-k9 h12-l8 j11-j12 h11-j9 h10-k8 k7-k13 g9-l10 f8-f13 g12-m11 j6-m9"
    var moves = moves_str.split(" ")
    var board = Board[values, 19, win_stones, 8]()
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
