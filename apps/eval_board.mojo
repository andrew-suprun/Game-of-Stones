from utils.numerics import inf
from game import Score
from board import Board, Place, first, second

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625, inf[DType.float32]())

fn main() raises:
    # var moves_str: String = "j10 i9-i10 i11-k9 l8-i7 j11-i8 k7-j7 h7-h11 g11-j6 l11-j9"
    # var moves_str: String = "j10 i9-i10 i11-k9 l8-i7 j11-i5 g13-g11 j12-h10 g9-j9 k13-g12 l14-e9"
    var moves_str: String = "j10 i9-i10 i11-k9 g12-h12 h10-j12"
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
            var board_value: Score
            if turn == first:
                score += board.score(place, first)
                value += board.score(place, first)
                print(place, board.score(place, first))
                board.place_stone(String(place), first)
                debug_assert(board.score(place, first) == board.board_value(values))
            else:
                score -= board.score(place, second)
                value -= board.score(place, second)
                print(place, board.score(place, second))
                board.place_stone(String(place), second)
                debug_assert(board.score(place, second) == board.board_value(values))
            print(board)
            print(board.str_scores())
            print("score", score)
            print("board", value)
        
        var opp_value = board.max_score(first) if turn == second else -board.max_score(second)

        print("opp", opp_value)
        print("score+opp", score+opp_value)
        print("board+opp", value + opp_value)

        turn = 1 - turn

    print(board)
    print(board.str_scores())
