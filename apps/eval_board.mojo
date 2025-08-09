from utils.numerics import inf
from game import Score
from board import Board, Place, first, second

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625, inf[DType.float32]())

fn main() raises:
    var moves_str: String = "j10 h9 i8 j12 k11 h8 " "h7 j9 i11 k9 i9 i10 h11 j11 k12 l9 k14 k10 i12 j13 j14 n9 m9 m8 n7 k13 i13 i14 h12 g11 h13 h14 l7 m13 k7 j7 j8 l6 l8 j6 o7 m7 n8 l10 i6 i7 g9 n10 n13 k5 l4 j5 j4 m5 l5 m10 o10 n11 k8 m6 m4 n4 g8 m11 o9 o11 f9 e10 i4 k4 g10 e8 p6 q5 g6 g7 g13 f14 k15 l16 e13 f13 o8 o6 f5 e4 q11 n12 o13 p10 q9 l14"
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
