@testable import Board
import Testing

@Test func testCalcValueTable() throws {
    let (black, white) = calcValuesTable([0, 1, 5, 25, 125, Score.infinity])
    
    print(black.count)
    for y in 0..<5 {
        for x in 0..<5 {
            print(black[y*5+x], terminator: " ")
        }
        print()
    }
    print()
    for y in 0..<5 {
        for x in 0..<5 {
            print(white[y*5+x], terminator: " ")
        }
        print()
    }
}

@Test func testPlace() throws {
    let p1 = Place("a1")!
    print("p1 = \(p1)")
    assert(p1.x == 0 && p1.y == 0)
    let p2 = Place("a19")!
    print("p2 = \(p2)")
    assert(p2.x == 0 && p2.y == 18)
    let p3 = Place("s1")!
    print("p3 = \(p3)")
    assert(p3.x == 18 && p3.y == 0)
    let p4 = Place("s19")!
    print("p4 = \(p4)")
    assert(p4.x == 18 && p4.y == 18)
}

@Test func testPlaceStone() throws {
    let values = [0, 1, 5, 25, 625, 3125, Score.infinity]
    var board = Board(maxPlaces: 20, values: values)
    var value = Score(0)

    for _ in 0..<200 {
        let turn = Int.random(in: 0...1)
        let x = Int.random(in: 0...boardSize - 1)
        let y = Int.random(in: 0...boardSize - 1)
        if board[x, y] == 0 {
            var failed = false
            for y in 0..<boardSize {
                for x in 0..<boardSize {
                    if board[x, y] == 0 {
                        let actual = board.getScores(x, y)
                        board.placeStone(place: Place(x, y), turn: first)
                        var expected = board.boardValue(values) - value
                        board.removeStone()
                        if actual[0] != expected {
                            failed = true
                            print("first:  \(Place(x, y)): actual \(actual[0]) expected \(expected)")
                        }
                        board.placeStone(place: Place(x, y), turn: second)
                        expected = value - board.boardValue(values)
                        board.removeStone()
                        if actual[1] != expected {
                            failed = true
                            print("second: \(Place(x, y)): actual \(actual[0]) expected \(expected)")
                        }
                    }
                }
            }
            if failed {
                print(board)
                print(board.strScores())
                try #require(!failed)
            }
            if turn == first {
                value += board.getScores(x, y)[turn]
            } else {
                value -= board.getScores(x, y)[turn]
            }
            board.placeStone(place: Place(x, y), turn: turn)
            print(board)
        }
    }
}

@Test func testTopPlaces() {
    let values = [0, 1, 5, 25, 625, 3125, Score.infinity]
    var board = Board(maxPlaces: 20, values: values)
    board.placeStone(place: Place(9, 9), turn: first)
    board.placeStone(place: Place(8, 9), turn: second)
    var topPlaces = [Place]()
    board.topPlaces(turn: first, topPlaces: &topPlaces)
    for i in 1..<20 {
        let parent = topPlaces[(i - 1) / 2]
        let child = topPlaces[i]
        assert(board.getScores(Int(parent.x), Int(parent.y))[0] <= board.getScores(Int(child.x), Int(child.y))[0])
    }
}


@Test func testDecition() {
    let values = [0, 1, 5, 25, 625, 3125, Score.infinity]
    var board = Board(maxPlaces: 20, values: values)

    board.placeStone(place: Place(0, 0), turn: first)
    board.placeStone(place: Place(0, 1), turn: first)
    board.placeStone(place: Place(0, 2), turn: first)
    board.placeStone(place: Place(0, 3), turn: first)
    board.placeStone(place: Place(0, 4), turn: first)
    board.placeStone(place: Place(1, 1), turn: first)
    board.placeStone(place: Place(2, 2), turn: first)
    board.placeStone(place: Place(3, 3), turn: first)
    board.placeStone(place: Place(4, 4), turn: first)
    board.placeStone(place: Place(1, 0), turn: first)
    board.placeStone(place: Place(2, 0), turn: first)
    board.placeStone(place: Place(3, 0), turn: first)
    board.placeStone(place: Place(4, 0), turn: first)

    board.placeStone(place: Place(18, 0), turn: second)
    board.placeStone(place: Place(18, 1), turn: second)
    board.placeStone(place: Place(18, 2), turn: second)
    board.placeStone(place: Place(18, 3), turn: second)
    board.placeStone(place: Place(18, 4), turn: second)
    board.placeStone(place: Place(17, 1), turn: second)
    board.placeStone(place: Place(16, 2), turn: second)
    board.placeStone(place: Place(15, 3), turn: second)
    board.placeStone(place: Place(14, 4), turn: second)
    board.placeStone(place: Place(17, 0), turn: second)
    board.placeStone(place: Place(16, 0), turn: second)
    board.placeStone(place: Place(15, 0), turn: second)
    board.placeStone(place: Place(14, 0), turn: second)

    board.placeStone(place: Place(18, 18), turn: first)
    board.placeStone(place: Place(17, 18), turn: first)
    board.placeStone(place: Place(16, 18), turn: first)
    board.placeStone(place: Place(15, 18), turn: first)
    board.placeStone(place: Place(14, 18), turn: first)
    board.placeStone(place: Place(18, 17), turn: first)
    board.placeStone(place: Place(18, 16), turn: first)
    board.placeStone(place: Place(18, 15), turn: first)
    board.placeStone(place: Place(18, 14), turn: first)
    board.placeStone(place: Place(17, 17), turn: first)
    board.placeStone(place: Place(16, 16), turn: first)
    board.placeStone(place: Place(15, 15), turn: first)
    board.placeStone(place: Place(14, 14), turn: first)
    
    board.placeStone(place: Place(0, 18), turn: second)
    board.placeStone(place: Place(1, 18), turn: second)
    board.placeStone(place: Place(2, 18), turn: second)
    board.placeStone(place: Place(3, 18), turn: second)
    board.placeStone(place: Place(4, 18), turn: second)
    board.placeStone(place: Place(1, 17), turn: second)
    board.placeStone(place: Place(2, 16), turn: second)
    board.placeStone(place: Place(3, 15), turn: second)
    board.placeStone(place: Place(4, 14), turn: second)
    board.placeStone(place: Place(0, 17), turn: second)
    board.placeStone(place: Place(0, 16), turn: second)
    board.placeStone(place: Place(0, 15), turn: second)
    board.placeStone(place: Place(0, 14), turn: second)

    print(board)

    print(board.decision())
    assert(board.decision() == .NoDecision)

    board.placeStone(place: Place(0, 5), turn: first)
    print(board.decision())
    assert(board.decision() == .FirstWin)
    board.removeStone()

    board.placeStone(place: Place(5, 5), turn: first)
    print(board.decision())
    assert(board.decision() == .FirstWin)
    board.removeStone()

    board.placeStone(place: Place(5, 0), turn: first)
    print(board.decision())
    assert(board.decision() == .FirstWin)
    board.removeStone()

    board.placeStone(place: Place(18, 5), turn: second)
    print(board.decision())
    assert(board.decision() == .SecondWin)
    board.removeStone()

    board.placeStone(place: Place(13, 5), turn: second)
    print(board.decision())
    assert(board.decision() == .SecondWin)
    board.removeStone()

    board.placeStone(place: Place(13, 0), turn: second)
    print(board.decision())
    assert(board.decision() == .SecondWin)
    board.removeStone()

    board.placeStone(place: Place(13, 18), turn: first)
    print(board.decision())
    assert(board.decision() == .FirstWin)
    board.removeStone()

    board.placeStone(place: Place(18, 13), turn: first)
    print(board.decision())
    assert(board.decision() == .FirstWin)
    board.removeStone()

    board.placeStone(place: Place(13, 13), turn: first)
    print(board.decision())
    assert(board.decision() == .FirstWin)
    board.removeStone()

    board.placeStone(place: Place(5, 18), turn: second)
    print(board.decision())
    assert(board.decision() == .SecondWin)
    board.removeStone()

    board.placeStone(place: Place(5, 13), turn: second)
    print(board.decision())
    assert(board.decision() == .SecondWin)
    board.removeStone()

    board.placeStone(place: Place(0, 13), turn: second)
    print(board.decision())
    assert(board.decision() == .SecondWin)
    board.removeStone()
}