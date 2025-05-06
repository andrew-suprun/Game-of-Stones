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
    print("Place = \(Place("a1")!)")
    print("Place = \(Place("a19")!)")
    print("Place = \(Place("s1")!)")
    print("Place = \(Place("s19")!)")
}