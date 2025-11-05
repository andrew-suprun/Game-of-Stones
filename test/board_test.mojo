from testing import assert_true, assert_false
from random import seed, random_si64

from score import Score
from board import Board, Place, first, second

alias size = 19
alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625)


fn test_place_stone() raises:
    seed(7)
    var board = Board[size, values, win_stones]()
    var value = Score(0)
    var n = 0
    for i in range(200):
        var turn = i % 2
        var xx = Int(random_si64(0, size - 1))
        var yy = Int(random_si64(0, size - 1))
        if board[xx, yy] == board.empty:
            for y in range(size):
                for x in range(size):
                    if board[x, y] == board.empty:
                        var actual = board.score(Place(x, y), first)
                        var b = board.copy()
                        b.place_stone(Place(x, y), first)
                        var expected = b.board_value(materialize[values]()) - value
                        if actual != expected:
                            print(Place(x, y), "actual:", actual, "first:", expected, "n", n)
                            print(b)
                            print(b.str_scores())
                            assert_true(False)
                        actual = board.score(Place(x, y), second)
                        b = board.copy()
                        b.place_stone(Place(x, y), second)
                        expected = value - b.board_value(materialize[values]())
                        if actual != expected:
                            print(Place(x, y), "actual:", actual, "second:", expected, "n", n)
                            print(b)
                            print(b.str_scores())
                            assert_true(False)
            if turn == first:
                value += board.score(Place(xx, yy), turn)
            else:
                value -= board.score(Place(xx, yy), turn)
            board.place_stone(Place(xx, yy), turn)
            n += 1



alias B = Board[19, values, win_stones]


fn place_stones(mut board: B, player: Int, stones: List[String]) raises:
    for stone in stones:
        board.place_stone(Place(stone), player)


fn check_results(mut board: B, player: Int, stones: List[String], expected: Score) raises:
    var b = board.copy()
    for stone in stones:
        b.place_stone(stone, player)
        print("#", stone, b._score)
        assert_true(b._score == expected)


fn main() raises:
    var board = Board[19, values, win_stones]()
    place_stones(board, first, ["a1", "a2", "a3", "a4", "a5", "b2", "c3", "d4", "e5", "b1", "c1", "d1", "e1"])
    place_stones(board, second, ["s1", "s2", "s3", "s4", "s5", "r2", "q3", "p4", "o5", "r1", "q1", "p1", "o1"])
    place_stones(board, first, ["s19", "s18", "s17", "s16", "s15", "r18", "q17", "p16", "o15", "r19", "q19", "p19", "o19"])
    place_stones(board, second, ["a19", "a18", "a17", "a16", "a15", "b18", "c17", "d16", "e15", "b19", "c19", "d19", "e19"])

    print(board)
    print(board.str_scores())

    assert_true(not board._score.is_decisive())

    check_results(board, first, ["f1", "f6", "a6"], Score.win())
    check_results(board, second, ["s6", "n6", "n1"], Score.loss())
    check_results(board, first, ["n19", "n14", "s14"], Score.win())
    check_results(board, second, ["a14", "f14", "f19"], Score.loss())
