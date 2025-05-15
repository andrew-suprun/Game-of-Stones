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