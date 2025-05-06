let boardSize = 19

public typealias Score = Float
public typealias Scores = SIMD2<Score>

struct Board {
    var places: [Int8] = Array(repeating: 0, count: boardSize * boardSize)
    var score = Score.zero
    let valueTable: ([SIMD2<Score>], [SIMD2<Score>])
    let winStones: Int

    init(maxStones: Int, values: [Score]) {
        self.winStones = maxStones
        self.valueTable = calcValuesTable(values)
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

func calcValuesTable(_ scores: [Score]) -> ([SIMD2<Score>], [SIMD2<Score>]) {
    let maxStones = scores.count - 1
    let resultSize = maxStones * maxStones + 1

    var v2 = [Scores]()
    v2.append(Scores(1, -1))

    for i in 0..<maxStones - 1 {
        v2.append(Scores(scores[i + 2] - scores[i + 1], -scores[i + 1]))
    }

    var result = ([SIMD2<Score>](repeating: Scores(0, 0), count: resultSize), 
                  [SIMD2<Score>](repeating: Scores(0, 0), count: resultSize))

    for i in 0..<maxStones - 1 {
        result.0[i * maxStones] = Scores(v2[i][1], -v2[i][0])
        result.0[i] = Scores(v2[i + 1][0] - v2[i][0], v2[i][1] - v2[i + 1][1])
        result.1[i] = Scores(-v2[i][0], v2[i][1])
        result.1[i * maxStones] = Scores(v2[i][1] - v2[i + 1][1], v2[i + 1][0] - v2[i][0])
    }

    return result
}
