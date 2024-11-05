package tree

import (
	"fmt"
	"game_of_stones/heap"
	"math"
	"time"
)

type iScore interface {
	comparable
	IsDrawing() bool
	IsWinning() bool
}

type iScoredMove[move any, score iScore] interface {
	Move() move
	Score() score
}

type iGame[move any, score iScore] interface {
	Turn() Player
	PlayMove(move)
	UndoMove(move)
	PossibleMoves(result *[]iScoredMove[move, score])
}

type Player int

const (
	First  Player = 1
	Second Player = 2
)

type node[move any, score iScore] struct {
	parent  uint32
	child   uint32
	sibling uint32
	move    move
	score   score
}

func Search[pMove iMove](game iGame[pMove], capacity int, duration time.Duration) pMove {
	root := &node[pMove]{}

	var leaves *heap.Heap[*node[pMove]]
	var limit int16

	if game.Turn() == First {
		leaves = heap.MakeHeap(capacity, maxLess[pMove])
		limit = math.MinInt16
	} else {
		leaves = heap.MakeHeap(capacity, minLess[pMove])
		limit = math.MaxInt16
	}

	var freeNodes *node[pMove]
	expand(root, game, leaves, &limit, freeNodes)
	if root.child.move.IsWinning() {
		return root.child.move
	}

	nodes := []*node[pMove]{}
	for node := root.child; node != nil; node = node.sibling {
		nodes = append(nodes, node)
	}

	depth := 0
	start := time.Now()
	for time.Since(start) < duration {
		depth++
		if depth%2 == 0 && game.Turn() == First || depth%2 == 1 && game.Turn() == Second {
			leaves = heap.MakeHeap(capacity, maxLess[pMove])
			limit = math.MinInt16
		} else {
			leaves = heap.MakeHeap(capacity, minLess[pMove])
			limit = math.MaxInt16
		}
		for idx := 0; idx < len(nodes); {
			if nodes[idx].move.IsDrawing() {
				idx++
				continue
			}
			switch expand(nodes[idx], game, leaves, &limit, freeNodes) {
			case win:
				nodes[idx] = nodes[len(nodes)-1]
				nodes = nodes[:len(nodes)-1]
				if len(nodes) == 1 {
					return nodes[0].move
				}
				continue
			case loss:
				return nodes[idx].move
			}
			idx++
		}
	}

	var bestMove pMove
	var bestScore int16
	if game.Turn() == First {
		bestScore = math.MinInt16
		for _, node := range nodes {
			nodeScore := node.bestScore(true)
			if bestScore < nodeScore {
				bestScore = nodeScore
				bestMove = node.move
			}
		}
	} else {
		bestScore = math.MaxInt16
		for _, node := range nodes {
			nodeScore := node.bestScore(false)
			if bestScore > nodeScore {
				bestScore = nodeScore
				bestMove = node.move
			}
		}
	}
	return bestMove
}

type expandResult int

const (
	inconclusive expandResult = iota
	win
	loss
	draw
)

func expand[pMove iMove](
	node *node[pMove],
	game iGame[pMove],
	leaves *heap.Heap[*node[pMove]],
	limit *int16,
	freeNodes *node[pMove],
) expandResult {
	if !node.alive {
		panic("expanding dead node")
	}
	node.draw = true
	if node.child == nil {
		hasChildren := false
		moves := game.PossibleMoves()
		for {
			move, ok := moves(*limit)
			if !ok {
				break
			}
			hasChildren = true
			if move.IsWinning() && node.parent != nil {
				node.removeSelf(freeNodes)
				return loss
			}
			child := node.addChild(move, freeNodes)
			if !child.move.IsDrawing() {
				node.draw = false
				if minNode, pushedOut := leaves.Add(child); pushedOut {
					if minNode.alive {
						*limit = minNode.move.Score()
						minNode.removeSelf(freeNodes)
					}
				}
			}
		}
		if !hasChildren {
			if node.parent == nil {
				panic("node.parent == nil")
			}
			node.parent.removeSelf(freeNodes)
		}
		if node.draw {
			return draw
		}
		return inconclusive
	}

	for child := node.child; child != nil; {
		if !child.alive {
			fmt.Println("dead child")
			continue
		}
		sibling := child.sibling
		if !child.draw {
			game.PlayMove(child.move)
			result := expand(child, game, leaves, limit, freeNodes)
			game.UndoMove(child.move)
			node.draw = node.draw && child.draw
			switch result {
			case win:
			case loss:
			case draw:
			case inconclusive:
			}
		}
		child = sibling
	}
	return inconclusive
}

func (parent *node[pMove]) addChild(move pMove, freeNodes *node[pMove]) *node[pMove] {
	var child *node[pMove]
	if freeNodes != nil {
		child = freeNodes
		if child.alive {
			panic("ALIVE")
		}
		freeNodes = child.parent
		child.parent = parent
		child.move = move
		child.draw = move.IsDrawing()
		child.alive = true
	} else {
		child = &node[pMove]{parent: parent, move: move, draw: move.IsDrawing(), alive: true}
	}
	if parent.child == nil {
		parent.child = child
	} else if parent.child.sibling == nil {
		parent.child.sibling = child
	} else {
		child.sibling = parent.child.sibling
		parent.child.sibling = child
	}
	return child
}

func (node *node[move]) removeSelf(freeNodes *node[move]) {
	if !node.alive {
		panic("node.removeSelf(): !node.alive")
	}

	parent := node.parent
	if parent.child == node {
		parent.child = node.sibling
	}

	for child := parent.child; child != nil; child = child.sibling {
		if child.sibling == node {
			child.sibling = node.sibling
			break
		}
	}

	node.parent = freeNodes
	node.child = nil
	node.sibling = nil
	node.alive = false
	freeNodes = node

	if parent.child == nil {
		if parent.parent == nil {
			panic("node.removeSelf(): parent.parent == nil")
		}
		parent.parent.removeSelf(freeNodes)
	}
}
