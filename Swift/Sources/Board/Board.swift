let boardSize = 19

public typealias Score = Float
public typealias Scores = SIMD2<Score>

enum Turn { case first, second }

struct PlaceScores {
    var offset: Int
    var scores: Scores
}

struct ScoreMark {
    var place: Place
    var score: Score
    var historyIdx: Int
}


struct Place: Equatable, Hashable, CustomStringConvertible {
    let x, y: UInt8

    init?(_ place: String) {
        let bytes = Array(place.utf8)
        let a = Array("a".utf8).first!
        if let first = bytes.first {
            let x  = first - a
            if let rest = String(validating: bytes.dropFirst(), as: UTF8.self) {
                if let y = UInt8(rest) {
                    self.x = x
                    self.y = y - 1
                    if x < boardSize && y < boardSize {
                        return
                    }
                }
            }
        }
        return nil
    }

    var description: String {
        let x = String(validating: [Array("a".utf8).first! + x], as: UTF8.self)
        let y = String(y + 1)
        return x!+y
    }
}

struct Board {
    var places: [Int8] = Array(repeating: 0, count: boardSize * boardSize)
    var score = Score.zero
    let valueTable: ([SIMD2<Score>], [SIMD2<Score>])
    let winStones: Int

    init(values: [Score]) {
        self.winStones = values.count - 1
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
