from engine import Board, Value, Place, first, second

comptime win_stones = 6
comptime values: List[Value] = [0, 1, 100, 1000, 10_000, 100_000]
# comptime win_stones = 5
# comptime values: List[Value] = [0, 1, 5, 25, 125]


def main() raises:
    var moves_str = "j10-j9"
    var moves = moves_str.split(" ")
    var board = Board[19, values, win_stones]()
    var value = Value(0)

    var turn = first
    for move in moves:
        var places = move.split("-")
        var score = Value(0)
        for place_str in places:
            print("----")
            var place = Place(String(place_str))
            if turn == first:
                board_score = board.get_value(place, first)
                score += board_score
                value += board_score
                print(place, board_score)
                if board_score == Value.MAX:
                    break
                board.place_stone(place, first)
            else:
                board_score = board.get_value(place, second)
                score -= board_score
                value -= board_score
                print(place, board_score)
                if board_score == Value.MAX:
                    break
                board.place_stone(place, second)
            assert value == board.debug_board_value(materialize[values]())
            print(repr(board))
            print("score", score)
            print("board", value)
            print("board value", board.value)

        var opp_value = board.max_value(first) if turn == second else -board.max_value(second)

        print("opp", opp_value)
        print("score+opp", score + opp_value)
        print("board+opp", value + opp_value)

        turn = 1 - turn
