import Foundation

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
                    if x < boardSize && y <= boardSize {
                        self.x = x
                        self.y = y - 1
                        return
                    }
                }
            }
        }
        return nil
    }

    var description: String {
        let x = String(validating: [Array("a".utf8).first! + x], as: UTF8.self)!
        let y = String(y + 1)
        return x+y
    }
}

struct Board {
    var places: [Int8] = Array(repeating: 0, count: boardSize * boardSize)
    var scores: [Scores] = Array(repeating: Scores(0, 0), count: boardSize * boardSize)
    var history: [PlaceScores] = []
    var history_indices: [ScoreMark] = []
    var score = Score.zero
    let valueTable: ([SIMD2<Score>], [SIMD2<Score>])
    let winStones: Int

    init(values: [Score]) {
        winStones = values.count - 1
        valueTable = calcValuesTable(values)

        for y in 0..<boardSize {
            let v = 1 + min(winStones - 1, y, boardSize - 1 - y)
            for x in 0..<boardSize {
                let h = 1 + min(winStones - 1, x, boardSize - 1 - x)
                let m = 1 + min(x, y, boardSize - 1 - x, boardSize - 1 - y)
                let t1 = max(0, min(winStones, m, boardSize - winStones + 1 - y + x, boardSize - winStones + 1 - x + y))
                let t2 = max(0, min(winStones, m, 2 * boardSize - 1 - winStones + 1 - y - x, x + y - winStones + 1 + 1))
                let total = v + h + t1 + t2
                let score = Float(total)
                self.setScores(x, y, Scores(score, score))
            }
        }
    }

    subscript(_ x: Int, _ y: Int) -> Int8 {
        get {
            return places[y * boardSize + x]
        }
        set {
            places[y * boardSize + y] = newValue
        }
    }

    func getScores(_ x: Int, _ y: Int) -> Scores {
        return scores[y * boardSize + x]
    }

    mutating func setScores(_ x: Int, _ y: Int, _ value: Scores) {
        scores[y * boardSize + x] = value
    }

    func strScores() -> String {
        var str = strScores(forPlayer: 0)
        str += strScores(forPlayer: 1)
        return str
    }

    func strScores(forPlayer player: Int) -> String {
        var str = String("\n   │")
        for i in 0..<UInt8(boardSize) {
            str += "    " + String(validating: [Array("a".utf8).first! + i], as: UTF8.self)! + " "
        }
        str += "│\n───┼"
        for _ in 0..<boardSize {
         str += "──────"
        }
        str += "┼───\n"

        for y in 0..<boardSize {
            str += String(format: "%2d", y + 1) + " │"
            for x in 0..<boardSize {
                let stone = self[x, y]
                if stone == 1 {
                    str += "    X "
                } else if stone == winStones {
                    str += "    O "
                } else {
                    let value = self.getScores(x, y)[player]
                    if value.isInfinite {
                        str += "  Win "
                    } else if value == 0.25 {
                        str += " Draw "
                    } else {
                        str += String(format: "%5d ", value)
                    }
                }
            }
            str += String(format: "│ %2d\n", y + 1)
        }
        str += "───┼"
        for _ in 0..<boardSize {
         str += "──────"
        }
        str += "┼───"

        if player == 1 {
            str += String("\n   │")
            for i in 0..<UInt8(boardSize) {
                str += "    " + String(validating: [Array("a".utf8).first! + i], as: UTF8.self)! + " "
            }
            str += "│\n"
        }

        return str
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
