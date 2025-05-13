import Foundation

protocol GameProtocol {
    associatedtype Move: MoveProtocol
    
    mutating func topMoves(_: [Move])
    mutating func playMove(_ move: Move)
    mutating func undoMove()
    func decision() -> Decision
}

public enum Decision: CustomStringConvertible { 
    case NoDecision, FirstWin, SecondWin, Draw

    public var description: String {
        return switch self {
            case .NoDecision: "no-decision"
            case .FirstWin: "first-win"
            case .SecondWin: "second-win"
            case .Draw: "draw"
        }
    }
}

protocol MoveProtocol: Comparable {
    init()

    var value: Float { get set }

    var isWin: Bool { get set }
    var isLoss: Bool { get set }
    var isDraw: Bool { get set }
    var isDecisive: Bool { get }
}

struct Tree<Game: GameProtocol> {
    var game: Game
    let c: Float
    var root: Node<Game> = Node<Game>(Game.Move())
    var topMoves: [Game.Move] = []
    var bestMove: Game.Move { root.bestMove }

    init(game: Game, c: Float) {
        self.game = game
        self.c = c
    }

    mutating func expand() -> Bool {
        if root.move.isDecisive {
            return true
        } else {
            root.expand(&game, c, &topMoves)
        }
        
        if root.move.isDecisive {
            return true
        }

        var undecided = 0
        for child in root.children {
            if !child.move.isDecisive {
                undecided += 1
            }
        }
        return undecided == 1
    }

    mutating func reset() {
        root = Node<Game>(Game.Move())
    }
}

struct Node<Game: GameProtocol> {
    var move: Game.Move
    var children: [Self] = []
    var nSims: Int32 = 1

    init(_ move: Game.Move) {
        self.move = move
    }

    mutating func expand(_ game: inout Game, _ c: Float, _ topMoves: inout [Game.Move]) {
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
                if children[childIdx].move.isDecisive {
                    continue
                }
                let v = children[childIdx].move.value + c * sqrt(logParentSims / Float(children[childIdx].nSims))
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
        move.value = Float.infinity
        var hasDraw = false
        var allDraws = true
        for child in children {
            if child.move.isWin {
                move.isLoss = true
                return
            } else if child.move.isDraw {
                hasDraw = true
                continue
            }
            allDraws = false
            if child.move.isLoss {
                continue
            }
            nSims += child.nSims
            if move.value >= -child.move.value {
                move.value = -child.move.value
            }
        }
        if allDraws {
            move.isDraw = true
        } else if hasDraw && move.value > 0 {
            move.value = 0
        }
    }

    var bestMove: Game.Move {
        assert(!children.isEmpty, "Function node.bestMove() is called with no children.")
        var bestChildIdx = 0
        for childIdx in children.indices {
            if children[bestChildIdx].move.value < children[childIdx].move.value {
                bestChildIdx = childIdx
            } else if children[bestChildIdx].move.isLoss && children[bestChildIdx].nSims < children[childIdx].nSims {
                bestChildIdx = childIdx
            }
        }
        return children[bestChildIdx].move
    }

}


