from testing import assert_true, assert_false
from random import seed, random_si64

from score import Score
from board import Board, Place, size, first, second

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625)


fn test_place_stone() raises:
    seed(7)
    var board = Board[values, win_stones]()
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
                        var b = board
                        b.place_stone(Place(x, y), first)
                        var expected = b.board_value(values) - value
                        if actual != expected:
                            print(Place(x, y), "actual:", actual, "first:", expected, "n", n)
                            print(b)
                            print(b.str_scores())
                            assert_true(False)
                        actual = board.score(Place(x, y), second)
                        b = board
                        b.place_stone(Place(x, y), second)
                        expected = value - b.board_value(values)
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


fn test_score() raises:
    var board = Board[values, win_stones]()

    board.place_stone("a1", first)
    board.place_stone("a2", first)
    board.place_stone("a3", first)
    board.place_stone("a4", first)
    board.place_stone("a5", first)
    board.place_stone("b2", first)
    board.place_stone("c3", first)
    board.place_stone("d4", first)
    board.place_stone("e5", first)
    board.place_stone("b1", first)
    board.place_stone("c1", first)
    board.place_stone("d1", first)
    board.place_stone("e1", first)

    board.place_stone("s1", second)
    board.place_stone("s2", second)
    board.place_stone("s3", second)
    board.place_stone("s4", second)
    board.place_stone("s5", second)
    board.place_stone("r2", second)
    board.place_stone("q3", second)
    board.place_stone("p4", second)
    board.place_stone("o5", second)
    board.place_stone("r1", second)
    board.place_stone("q1", second)
    board.place_stone("p1", second)
    board.place_stone("o1", second)

    board.place_stone("s19", first)
    board.place_stone("s18", first)
    board.place_stone("s17", first)
    board.place_stone("s16", first)
    board.place_stone("s15", first)
    board.place_stone("r18", first)
    board.place_stone("q17", first)
    board.place_stone("p16", first)
    board.place_stone("o15", first)
    board.place_stone("r19", first)
    board.place_stone("q19", first)
    board.place_stone("p19", first)
    board.place_stone("o19", first)

    board.place_stone("a19", second)
    board.place_stone("a18", second)
    board.place_stone("a17", second)
    board.place_stone("a16", second)
    board.place_stone("a15", second)
    board.place_stone("b18", second)
    board.place_stone("c17", second)
    board.place_stone("d16", second)
    board.place_stone("e15", second)
    board.place_stone("b19", second)
    board.place_stone("c19", second)
    board.place_stone("d19", second)
    board.place_stone("e19", second)

    print(board)
    print(board.str_scores())

    print("#0", board._score)
    assert_true(not board._score.is_decisive())

    var b = board
    b.place_stone("f1", first)
    print("#1", b._score)
    assert_true(b._score.is_win())

    b = board
    b.place_stone("f6", first)
    print("#2", b._score)
    assert_true(b._score.is_win())

    b = board
    b.place_stone("a6", first)
    print("#3", b._score)
    assert_true(b._score.is_win())

    b = board
    b.place_stone("s6", second)
    print("#4", b._score)
    assert_true(b._score.is_loss())

    b = board
    b.place_stone("n6", second)
    print("#5", b._score)
    assert_true(b._score.is_loss())

    b = board
    b.place_stone("n1", second)
    print("#6", b._score)
    assert_true(b._score.is_loss())

    b = board
    b.place_stone("n19", first)
    print("#7", b._score)
    assert_true(b._score.is_win())

    b = board
    b.place_stone("n14", first)
    print("#8", b._score)
    assert_true(b._score.is_win())

    b = board
    b.place_stone("s14", first)
    print("#9", b._score)
    assert_true(b._score.is_win())

    b = board
    b.place_stone("a14", second)
    print("#10", b._score)
    assert_true(b._score.is_loss())

    b = board
    b.place_stone("f14", second)
    print("#11", b._score)
    assert_true(b._score.is_loss())

    b = board
    b.place_stone("f19", second)
    print("#12", b._score)
    assert_true(b._score.is_loss())


fn test_connected_to() raises:
    assert_false(Place(2, 5).connected_to[5](Place(7, 5)))
    assert_true(Place(2, 5).connected_to[6](Place(7, 5)))
    assert_true(Place(2, 5).connected_to[6](Place(7, 10)))
    assert_true(Place(2, 5).connected_to[6](Place(3, 4)))
    assert_false(Place(2, 5).connected_to[6](Place(3, 7)))
