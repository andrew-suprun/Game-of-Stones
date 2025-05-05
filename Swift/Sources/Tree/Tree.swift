import Foundation

protocol Game {
    associatedtype M: Move
    
    mutating func topMoves(_: [(M, Float)])
    mutating func playMove(_ move: M)
    mutating func undoMove()
}

protocol Move {
    init()
}

// protocol Score: Comparable {
//     init(_ value: Float)
//     static var loss: Self {get}
//     static var win: Self {get}
//     static var draw: Self {get}

//     var isWin: Bool { get }
//     var isLoss: Bool { get }
//     var isDraw: Bool { get }
//     var isDecisive: Bool {get}

//     var value: Float {get}
// }


let win = Float.infinity
let loss = -Float.infinity
let draw = Float(0.25)

struct Tree<G: Game> {
    var game: G
    var c: Float
    var root: Node<G> = Node<G>((G.M(), 0))
    var topMoves: [(G.M, Float)] = []
    var score: Float { -root.score }
    var bestMove: G.M { root.bestMove }

    init(game: G, c: Float) {
        self.game = game
        self.c = c
    }

    mutating func expand() -> Bool {
        if root.isDecisive {
            return true
        } else {
            root.expand(&game, c, &topMoves)
        }
        
        if root.isDecisive {
            return true
        }

        var undecided = 0
        for child in root.children {
            if !child.isDecisive {
                undecided += 1
            }
        }
        return undecided == 1
    }

    mutating func reset() {
        root = Node<G>((G.M(), 0))
    }
}

struct Node<G: Game> {
    var move: G.M
    var score: Float
    var children: [Self] = []
    var nSims: Int32 = 1

    init(_ moveScore: (G.M, Float)) {
        self.move = moveScore.0
        self.score = moveScore.1
    }

    var isWin: Bool { get { score == win } }
    var isLoss: Bool { get { score == loss } }
    var isDraw: Bool { get { score == draw } }
    var isDecisive: Bool { get { score.isInfinite || score == draw}}

    mutating func expand(_ game: inout G, _ c: Float, _ topMoves: inout [(G.M, Float)]) {
        if children.isEmpty {
            game.topMoves(topMoves)
            assert(!topMoves.isEmpty, "Function top<oves(...) returns empty result.")

            children.reserveCapacity(topMoves.count)
            for move in topMoves {
                children.append(Node(move))
            }
        } else {
            var selectedChildIdx = 0
            let nSims = nSims
            let logParentSims = log2f(Float(nSims))
            var maxV = -Float.infinity
            for childIdx in children.indices {
                if children[childIdx].isDecisive {
                    continue
                }
                let v = children[childIdx].score + c * sqrt(logParentSims / Float(children[childIdx].nSims))
                if v > maxV {
                    maxV = v
                    selectedChildIdx = childIdx
                }
            }
            game.playMove(children[selectedChildIdx].move)
            children[selectedChildIdx].expand(&game, c, &topMoves)
            game.undoMove()
        }

        nSims = 0
        score = Float.infinity
        var hasDraw = false
        var allDraws = true
        for child in children {
            if child.isWin {
                score = -child.score
                return
            } else if child.isDraw {
                hasDraw = true
                continue
            }
            allDraws = false
            if child.isLoss {
                continue
            }
            nSims += child.nSims
            if score >= -child.score {
                score = -child.score
            }
        }
        if allDraws {
            score = draw
        } else if hasDraw && score > 0 {
            score = 0
        }
    }

    var bestMove: G.M {
        assert(!children.isEmpty, "Function node.bestMove() is called with no children.")
        var bestChildIdx = 0
        for childIdx in children.indices {
            if children[bestChildIdx].score < children[childIdx].score {
                bestChildIdx = childIdx
            } else if children[bestChildIdx].isLoss && children[bestChildIdx].nSims < children[childIdx].nSims {
                bestChildIdx = childIdx
            }
        }
        return children[bestChildIdx].move
    }

}


