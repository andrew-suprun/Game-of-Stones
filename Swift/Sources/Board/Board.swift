let boardSize = 19

typealias Score = Float32

struct Board {
    var places: [Int8] = Array(repeating: 0, count: boardSize * boardSize)
    var score = Score.zero
    let valueTable: ([SIMD2<Score>], [SIMD2<Score>])
    let winStones: Int

    init(maxStones: Int, values: [Score]) {
        self.winStones = maxStones
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
