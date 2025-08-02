from testing import assert_true, assert_false
from random import seed, random_si64

from game import Score, undecided, first_wins, second_wins
from board import Board, Place, first, second

alias win_stones = 6
alias values = List[Float32](0, 1, 5, 25, 125, 625)

fn test_place_stone() raises:
    seed(7)
    var board = Board[values, 19, win_stones, 20]()
    var value = Score(0)
    var n = 0
    for i in range(200):
        var turn = i % 2
        var xx = Int(random_si64(0, board.size - 1))
        var yy = Int(random_si64(0, board.size - 1))
        print("place", Place(xx, yy))
        if board[xx, yy] == board.empty:
            var fail = False
            for y in range(board.size):
                for x in range(board.size):
                    if board[x, y] == board.empty:
                        var actual = board.score[first](Place(x, y))
                        var b = board
                        b.place_stone[first](Place(x, y))
                        var expected = b.board_value(values) - value
                        if actual != expected:
                            print(Place(x, y), "actual:", actual, "first:", expected, "n", n)
                            fail = True
                        actual = board.score[second](Place(x, y))
                        b = board
                        b.place_stone[second](Place(x, y))
                        expected = b.board_value(values) - value
                        if actual != expected:
                            print(Place(x, y), "actual:", actual, "second:", expected, "n", n)
                            fail = True
            if fail:
                print(board)
                print(board.str_scores())
                assert_true(False)

            if turn == first:
                value += board.score[first](Place(xx, yy))
                board.place_stone[first](Place(xx, yy))
            else:
                value += board.score[second](Place(xx, yy))
                board.place_stone[second](Place(xx, yy))
            n += 1

fn test_places() raises:
    var board = Board[values, 19, win_stones, 20]()
    board.place_stone[first](Place(9, 9))
    board.place_stone[second](Place(8, 9))
    var places = board.places[first]()
    for i in range(0, 19):
        assert_true(board.score[first](places[i]) >= board.score[first](places[i+1]))

    places = board.places[second]()
    for i in range(0, 19):
        assert_true(board.score[second](places[i]) <= board.score[second](places[i+1]))

fn test_decision() raises:
    var board = Board[values, 19, win_stones, 20]()

    board.place_stone[first](Place(0, 0))
    board.place_stone[first](Place(0, 1))
    board.place_stone[first](Place(0, 2))
    board.place_stone[first](Place(0, 3))
    board.place_stone[first](Place(0, 4))
    board.place_stone[first](Place(1, 1))
    board.place_stone[first](Place(2, 2))
    board.place_stone[first](Place(3, 3))
    board.place_stone[first](Place(4, 4))
    board.place_stone[first](Place(1, 0))
    board.place_stone[first](Place(2, 0))
    board.place_stone[first](Place(3, 0))
    board.place_stone[first](Place(4, 0))

    board.place_stone[second](Place(18, 0))
    board.place_stone[second](Place(18, 1))
    board.place_stone[second](Place(18, 2))
    board.place_stone[second](Place(18, 3))
    board.place_stone[second](Place(18, 4))
    board.place_stone[second](Place(17, 1))
    board.place_stone[second](Place(16, 2))
    board.place_stone[second](Place(15, 3))
    board.place_stone[second](Place(14, 4))
    board.place_stone[second](Place(17, 0))
    board.place_stone[second](Place(16, 0))
    board.place_stone[second](Place(15, 0))
    board.place_stone[second](Place(14, 0))

    board.place_stone[first](Place(18, 18))
    board.place_stone[first](Place(17, 18))
    board.place_stone[first](Place(16, 18))
    board.place_stone[first](Place(15, 18))
    board.place_stone[first](Place(14, 18))
    board.place_stone[first](Place(18, 17))
    board.place_stone[first](Place(18, 16))
    board.place_stone[first](Place(18, 15))
    board.place_stone[first](Place(18, 14))
    board.place_stone[first](Place(17, 17))
    board.place_stone[first](Place(16, 16))
    board.place_stone[first](Place(15, 15))
    board.place_stone[first](Place(14, 14))

    board.place_stone[second](Place(0, 18))
    board.place_stone[second](Place(1, 18))
    board.place_stone[second](Place(2, 18))
    board.place_stone[second](Place(3, 18))
    board.place_stone[second](Place(4, 18))
    board.place_stone[second](Place(1, 17))
    board.place_stone[second](Place(2, 16))
    board.place_stone[second](Place(3, 15))
    board.place_stone[second](Place(4, 14))
    board.place_stone[second](Place(0, 17))
    board.place_stone[second](Place(0, 16))
    board.place_stone[second](Place(0, 15))
    board.place_stone[second](Place(0, 14))

    print(board)

    print(1)
    print(board.decision())
    print(2)
    assert_true(board.decision() == undecided)
    print(2.5)

    var b = board
    b.place_stone[first](Place(0, 5))
    print(3)
    print(b.decision())
    print(4)
    assert_true(b.decision() == first_wins)

    b = board
    b.place_stone[first](Place(5, 5))
    print(b.decision())
    assert_true(b.decision() == first_wins)

    b = board
    b.place_stone[first](Place(5, 0))
    print(b.decision())
    assert_true(b.decision() == first_wins)

    b = board
    b.place_stone[second](Place(18, 5))
    print(b.decision())
    assert_true(b.decision() == second_wins)

    b = board
    b.place_stone[second](Place(13, 5))
    print(b.decision())
    assert_true(b.decision() == second_wins)

    b = board
    b.place_stone[second](Place(13, 0))
    print(b.decision())
    assert_true(b.decision() == second_wins)

    b = board
    b.place_stone[first](Place(13, 18))
    print(b.decision())
    assert_true(b.decision() == first_wins)

    b = board
    b.place_stone[first](Place(18, 13))
    print(b.decision())
    assert_true(b.decision() == first_wins)

    b = board
    b.place_stone[first](Place(13, 13))
    print(b.decision())
    assert_true(b.decision() == first_wins)

    b = board
    b.place_stone[second](Place(5, 18))
    print(b.decision())
    assert_true(b.decision() == second_wins)

    b = board
    b.place_stone[second](Place(5, 13))
    print(b.decision())
    assert_true(b.decision() == second_wins)

    b = board
    b.place_stone[second](Place(0, 13))
    print(b.decision())
    assert_true(b.decision() == second_wins)

fn test_connected_to() raises:
    assert_false(Place(2, 5).connected_to[5](Place(7, 5)))
    assert_true(Place(2, 5).connected_to[6](Place(7, 5)))
    assert_true(Place(2, 5).connected_to[6](Place(7, 10)))
    assert_true(Place(2, 5).connected_to[6](Place(3, 4)))
    assert_false(Place(2, 5).connected_to[6](Place(3, 7)))