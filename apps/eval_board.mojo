from utils.numerics import inf
from game import Score
from board import Board, Place, first, second

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625, inf[DType.float32]())

fn main() raises:
    var moves_str: String = "j10 h12-h9 k9-l12 l12-i8 j7-m7 h10-h11 h7-h13 i11-j11 i7-k11 j8-k7 i9-l8 f11-n6 e11-g7 f7-h8 f8-k12 e12-i10 g8-g10 f12-g12 d12-j12 f13-f14 d12-j12 e14-j9"
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
