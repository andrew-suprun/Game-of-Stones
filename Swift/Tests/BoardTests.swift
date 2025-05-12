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

@Test func testScores() throws {
    let board = Board(values: [0, 1, 5, 25, 625, Score.infinity])
    print("board:" + board.strScores())
}
