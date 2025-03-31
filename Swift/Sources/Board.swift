let boardSize = 19

struct Board<Score: SIMDScalar & Numeric> {
    var places: [Int8] = Array(repeating: 0, count: boardSize * boardSize)
    var score = Score.zero
    let valueTable: ([SIMD2<Score>], [SIMD2<Score>])
    let maxStones: Int  // TODO: compare performance vs. maxStones as static constant; both gomoku and connect6

    init(maxStones: Int, values: [Score]) {
        self.maxStones = maxStones
        self.valueTable = calcValueTable(values)
    }

    subscript(_ x: Int, _ y: Int) -> Int8 {
        get {
            return places[y * boardSize + x]
        }
        set {
            places[y * boardSize + y] = newValue
        }
    }

}

func calcValueTable<Score: SIMDScalar & Numeric>(_ values: [Score])
    -> ([SIMD2<Score>], [SIMD2<Score>])
{
    return ([SIMD2<Score>](), [SIMD2<Score>]())
}
