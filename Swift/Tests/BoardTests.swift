@testable import Board
import Testing

@Test func calcValueTableTest() throws {
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