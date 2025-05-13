import Foundation
import Heap

let boardSize = 19
let first = 0
let second = 1

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

    init(_ x: Int, _ y: Int) {
        self.x = UInt8(x)
        self.y = UInt8(y)
    }

    init?(_ place: String) {
        let bytes = Array(place.utf8)
        let a = "a".utf8.first!
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
        let x = String(format: "%c", "a".utf8.first! + x)
        let y = String(y + 1)
        return x+y
    }
}

struct Board: CustomStringConvertible {
    var places: [Int8] = Array(repeating: 0, count: boardSize * boardSize)
    var scores: [Scores] = Array(repeating: Scores(0, 0), count: boardSize * boardSize)
    var history: [PlaceScores] = []
    var historyIndices: [ScoreMark] = []
    var score = Score.zero
    let valueTable: ([SIMD2<Score>], [SIMD2<Score>])
    let winStones: Int
    let maxPlaces: Int

    init(maxPlaces: Int, values: [Score]) {
        self.maxPlaces = maxPlaces
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
                setScores(x, y, Scores(score, score))
            }
        }
    }

    public mutating func placeStone(place: Place, turn: Int) {
        let scores = turn == first ? valueTable.0 : valueTable.1
        historyIndices.append(ScoreMark(place: place, score: self.score, historyIdx: history.count))

        let x = Int(place.x)
        let y = Int(place.y)

        if turn == first {
            score += getScores(x, y)[first]
        } else {
            score -= getScores(x, y)[second]
        }

        let xStart = max(0, x - winStones + 1)
        let xEnd = min(x + winStones, boardSize) - winStones + 1
        var n = xEnd - xStart
        updateRow(start: y * boardSize + xStart, delta: 1, n, scores)

        let yStart = max(0, y - winStones + 1)
        let yEnd = min(y + winStones, boardSize) - winStones + 1
        n = yEnd - yStart
        updateRow(start: yStart * boardSize + x, delta: boardSize, n, scores)

        let m = 1 + min(x, y, boardSize - 1 - x, boardSize - 1 - y)

        n = min(winStones, m, boardSize - winStones + 1 - y + x, boardSize - winStones + 1 - x + y)
        if n > 0 {
            let mn = min(x, y, winStones - 1)
            let x_start = x - mn
            let y_start = y - mn
            updateRow(start: y_start * boardSize + x_start, delta: boardSize + 1, n, scores)
        }

        n = min(winStones, m, 2 * boardSize - winStones - y - x, x + y - winStones + 2)
        if n > 0 {
            let mn = min(boardSize - 1 - x, y, winStones - 1)
            let x_start = x + mn
            let y_start = y - mn
            updateRow(start: y_start * boardSize + x_start, delta: boardSize - 1, n, scores)
        }

        if turn == first {
            self[x, y] = 1
        } else {
            self[x, y] = Int8(winStones)
        }
    }

    public mutating func updateRow(start: Int, delta: Int, _ n: Int, _ scores: [SIMD2<Score>]) {
        var i = start
        while i < start + delta * (winStones - 1 + n) {
            history.append(PlaceScores(offset: i, scores: self.scores[i]))
            i += delta
        }

        var offset = start
        var stones = 0

        for i in 0..<winStones - 1 {
            stones += Int(places[offset + i * delta])
        }

        for _ in 0..<n {
            stones += Int(places[offset + delta * (winStones - 1)])
            let scores = scores[stones]
            if scores[0] != 0 || scores[1] != 0 {
                for j in 0..<winStones {
                    self.scores[offset + j * delta] += scores
                }
            }
            stones -= Int(places[offset])
            offset += delta
        }
    }

    public mutating func removeStone() {
        let idx = historyIndices.removeLast()
        self[Int(idx.place.x), Int(idx.place.y)] = 0
        score = idx.score
        while history.count > idx.historyIdx {
            let h_scores = self.history.removeLast()
            scores[h_scores.offset] = h_scores.scores
        }
    }

    public func topPlaces(turn: Int, topPlaces: inout [Place]) {
        func lessFirst(a: Place, b: Place) -> Bool {
            return getScores(Int(a.x), Int(a.y))[0] < self.getScores(Int(b.x), Int(b.y))[0]
        }

        func lessSecond(a: Place, b: Place) -> Bool {
            return getScores(Int(a.x), Int(a.y))[1] < self.getScores(Int(b.x), Int(b.y))[1]
        }

        topPlaces.removeAll(keepingCapacity: true)

        if turn == first {
            for y in 0..<boardSize {
                for x in 0..<boardSize {
                    if self[x, y] == 0 && getScores(x, y)[first] > 0 {
                        heapAdd(Place(x, y), to: &topPlaces, maxItems: maxPlaces) {
                            getScores(Int($0.x), Int($0.y))[0] < self.getScores(Int($1.x), Int($1.y))[0]
                        }
                    }
                }
            }
        } else {
            for y in 0..<boardSize {
                for x in 0..<boardSize {
                    if self[x, y] == 0 && getScores(x, y)[second] > 0 {
                        heapAdd(Place(x, y), to: &topPlaces, maxItems: maxPlaces) {
                            getScores(Int($0.x), Int($0.y))[1] < self.getScores(Int($1.x), Int($1.y))[1]
                        }
                    }
                }
            }
        }
    }

    public func maxScore(player: Int) -> Score {
        var r = -Score.infinity
        if player == 0 {
            for (i, scores) in scores.enumerated() {
                if r < scores[0] && places[i] == 0 {
                    r = score
                }
            }
        } else {
            for (i, scores) in scores.enumerated() {
                if r < scores[1] && places[i] == 0 {
                    r = score
                }
            }
        }
        return r
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

    var description: String {
        var str = "\n  "

        for i in 0..<UInt8(boardSize) {
            str += String(format: " %c", "a".utf8.first! + i)
        }
        str += "\n"

        for y in 0..<boardSize {
            str += String(format: "%2d",y + 1)
            for x in 0..<boardSize {
                let stone = self[x, y]
                if stone == 1 {
                    str += x == 0 ? " X" : "─X"
                } else if stone == winStones {
                    str += x == 0 ? " O" : "─O"
                } else {
                    if y == 0 {
                        str += x == 0 ? " ┌" : x == boardSize - 1 ? "─┐" : "─┬"
                    } else if y == boardSize - 1 {
                        str += x == 0 ? " └" : x == boardSize - 1 ? "─┘" : "─┴"
                    } else {
                        str += x == 0 ? " ├" : x == boardSize - 1 ? "─┤" : "─┼"
                    }
                }
            }
            str += String(format: "%3d\n",y + 1)
        }

        str += "  "

        for i in 0..<UInt8(boardSize) {
            str += String(format: " %c", "a".utf8.first! + i)
        }
        str += "\n"

        return str
    }

    func strScores() -> String {
        var str = strScores(forPlayer: 0)
        str += strScores(forPlayer: 1)
        return str
    }

    func strScores(forPlayer player: Int) -> String {
        var str = String("\n   │")
        for i in 0..<UInt8(boardSize) {
            str += "    " + String(format: "%c", "a".utf8.first! + i) + " "
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
                    let value = getScores(x, y)[player]
                    if value.isInfinite {
                        str += "  Win "
                    } else if value == 0.25 {
                        str += " Draw "
                    } else {
                        str += String(format: "%5.0f ", value)
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
                str += "    " + String(format: "%c", "a".utf8.first! + i) + " "
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
