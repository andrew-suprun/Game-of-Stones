from testing import assert_true
from random import seed, random_si64

from board import Board, Place, Score, first, second

alias max_stones = 6
alias values = List[Score](0, 1, 5, 25, 125, 625)


fn test_place_stone() raises:
    seed(7)
    var board = Board[values, 19, max_stones, 20]()
    var value = Score(0)
    var n = 0
    for i in range(200):
        var turn = i % 2
        var xx = Int(random_si64(0, board.size - 1))
        var yy = Int(random_si64(0, board.size - 1))
        if board[xx, yy] == board.empty:
            for y in range(board.size):
                for x in range(board.size):
                    if board[x, y] == board.empty:
                        var actual = board.getscores(Place(x, y))
                        var b = board
                        b.place_stone(Place(x, y), first)
                        var expected = b.board_value(values) - value
                        if actual[0] != expected.value():
                            print(Place(x, y), "actual:", actual, "first:", expected, "n", n)
                            print(b)
                            print(b.str_scores())
                            assert_true(False)
                        b = board
                        b.place_stone(Place(x, y), second)
                        expected = value - b.board_value(values)
                        if actual[1] != expected.value():
                            print(Place(x, y), "actual:", actual, "second:", expected, "n", n)
                            print(b)
                            print(b.str_scores())
                            assert_true(False)
            if turn == first:
                value += board.getscores(Place(xx, yy))[turn]
            else:
                value -= board.getscores(Place(xx, yy))[turn]
            board.place_stone(Place(xx, yy), turn)
            n += 1

fn test_places() raises:
    var board = Board[values, 19, max_stones, 20]()
    board.place_stone(Place(9, 9), 0)
    board.place_stone(Place(8, 9), 1)
    var places = board.places(0)
    
    for i in range(1, 20):
        var parent = places[(i - 1) // 2]
        var child = places[i]
        assert_true(board.getscores(parent)[0] <= board.getscores(child)[0])

fn test_decision() raises:
    var board = Board[values, 19, max_stones, 20]()

    board.place_stone(Place(0, 0), first)
    board.place_stone(Place(0, 1), first)
    board.place_stone(Place(0, 2), first)
    board.place_stone(Place(0, 3), first)
    board.place_stone(Place(0, 4), first)
    board.place_stone(Place(1, 1), first)
    board.place_stone(Place(2, 2), first)
    board.place_stone(Place(3, 3), first)
    board.place_stone(Place(4, 4), first)
    board.place_stone(Place(1, 0), first)
    board.place_stone(Place(2, 0), first)
    board.place_stone(Place(3, 0), first)
    board.place_stone(Place(4, 0), first)

    board.place_stone(Place(18, 0), second)
    board.place_stone(Place(18, 1), second)
    board.place_stone(Place(18, 2), second)
    board.place_stone(Place(18, 3), second)
    board.place_stone(Place(18, 4), second)
    board.place_stone(Place(17, 1), second)
    board.place_stone(Place(16, 2), second)
    board.place_stone(Place(15, 3), second)
    board.place_stone(Place(14, 4), second)
    board.place_stone(Place(17, 0), second)
    board.place_stone(Place(16, 0), second)
    board.place_stone(Place(15, 0), second)
    board.place_stone(Place(14, 0), second)

    board.place_stone(Place(18, 18), first)
    board.place_stone(Place(17, 18), first)
    board.place_stone(Place(16, 18), first)
    board.place_stone(Place(15, 18), first)
    board.place_stone(Place(14, 18), first)
    board.place_stone(Place(18, 17), first)
    board.place_stone(Place(18, 16), first)
    board.place_stone(Place(18, 15), first)
    board.place_stone(Place(18, 14), first)
    board.place_stone(Place(17, 17), first)
    board.place_stone(Place(16, 16), first)
    board.place_stone(Place(15, 15), first)
    board.place_stone(Place(14, 14), first)

    board.place_stone(Place(0, 18), second)
    board.place_stone(Place(1, 18), second)
    board.place_stone(Place(2, 18), second)
    board.place_stone(Place(3, 18), second)
    board.place_stone(Place(4, 18), second)
    board.place_stone(Place(1, 17), second)
    board.place_stone(Place(2, 16), second)
    board.place_stone(Place(3, 15), second)
    board.place_stone(Place(4, 14), second)
    board.place_stone(Place(0, 17), second)
    board.place_stone(Place(0, 16), second)
    board.place_stone(Place(0, 15), second)
    board.place_stone(Place(0, 14), second)

    print(board)

    print(board.decision())
    assert_true(board.decision() == "no-decision")

    var b = board
    b.place_stone(Place(0, 5), first)
    print(b.decision())
    assert_true(b.decision() == "first-win")

    b = board
    b.place_stone(Place(5, 5), first)
    print(b.decision())
    assert_true(b.decision() == "first-win")

    b = board
    b.place_stone(Place(5, 0), first)
    print(b.decision())
    assert_true(b.decision() == "first-win")

    b = board
    b.place_stone(Place(18, 5), second)
    print(b.decision())
    assert_true(b.decision() == "second-win")

    b = board
    b.place_stone(Place(13, 5), second)
    print(b.decision())
    assert_true(b.decision() == "second-win")

    b = board
    b.place_stone(Place(13, 0), second)
    print(b.decision())
    assert_true(b.decision() == "second-win")

    b = board
    b.place_stone(Place(13, 18), first)
    print(b.decision())
    assert_true(b.decision() == "first-win")

    b = board
    b.place_stone(Place(18, 13), first)
    print(b.decision())
    assert_true(b.decision() == "first-win")

    b = board
    b.place_stone(Place(13, 13), first)
    print(b.decision())
    assert_true(b.decision() == "first-win")

    b = board
    b.place_stone(Place(5, 18), second)
    print(b.decision())
    assert_true(b.decision() == "second-win")

    b = board
    b.place_stone(Place(5, 13), second)
    print(b.decision())
    assert_true(b.decision() == "second-win")

    b = board
    b.place_stone(Place(0, 13), second)
    print(b.decision())
    assert_true(b.decision() == "second-win")
