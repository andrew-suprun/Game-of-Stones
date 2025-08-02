from utils.numerics import inf
from game import Score
from board import Board, Place, first, second

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625, inf[DType.float32]())

fn main() raises:
    var moves_str: String = "j10 i9-i10 i11-k9 h12-i7 i6-k8"
    var moves = moves_str.split(" ")
    var board = Board[values, 19, win_stones, 8]()
    var value = Score(0)

    var turn = first
    for move in moves:
        print("----")
        var places = move.split("-")
        var score = Score(0)
        for place_str in places:
            var place = Place(String(place_str))
            if turn == first:
                score += board.score[first](place)
                value += board.score[first](place)
                print(place, board.score[first](place))
                board.place_stone[first](String(place))
            else:
                score += board.score[second](place)
                value += board.score[second](place)
                print(place, board.score[second](place))
                board.place_stone[second](String(place))
            print(board)
            print(board.str_scores())
        
        var opp_value: Float32
        if turn == first:
            opp_value = board.max_score[second]()
        else:
            opp_value = board.max_score[first]()

        print("score", score)
        print("opp", opp_value)
        print("score+opp", score+opp_value)
        print("board", value)
        print("board+opp", value + opp_value)

        turn = 1 - turn