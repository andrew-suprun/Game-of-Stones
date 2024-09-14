package tree

import (
	"bytes"
	"fmt"
	"math"
)

type node[move iMove] struct {
	parent   *node[move]
	children []*node[move]
	selfIdx  uint16
	move     move
	draw     bool
}

func (n *node[pMove]) addMoves(moves []pMove) {
	n.children = make([]*node[pMove], len(moves))
	for i, move := range moves {
		n.children[i] = &node[pMove]{parent: n, selfIdx: uint16(i), move: move, draw: move.IsDraw()}
	}
}

func maxLess[move iMove](a, b *node[move]) bool {
	return a.move.Score() < b.move.Score()
}

func minLess[move iMove](a, b *node[move]) bool {
	return a.move.Score() > b.move.Score()
}

func (node *node[move]) bestMove(maxer bool) (move, int16) {
	var bestMove move
	if maxer {
		var bestScore int16 = math.MinInt16
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestMove = child.move
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	} else {
		var bestScore int16 = math.MaxInt16
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore > childScore {
				bestMove = child.move
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	}
}

func (node *node[_]) bestScore(maxer bool) int16 {
	if len(node.children) == 0 {
		return node.move.Score()
	}

	if maxer {
		var bestScore int16 = math.MinInt16
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestScore = childScore
			}
		}
		return bestScore
	} else {
		var bestScore int16 = math.MaxInt16
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore > childScore {
				bestScore = childScore
			}
		}
		return bestScore
	}
}

func (node *node[_]) Print() {
	node.print(0)
}

func (node *node[_]) print(level int) {
	for range level {
		fmt.Print(" |")
	}

	fmt.Printf("%s\n", node.move.String())
	for _, child := range node.children {
		child.print(level + 1)
	}
}

func (node *node[_]) String() string {
	return node.move.String()
}

func (node *node[_]) Bytes() []byte {
	buf := &bytes.Buffer{}
	node.bytes(buf, 0)
	return buf.Bytes()
}

func (node *node[_]) bytes(buf *bytes.Buffer, level int) {
	for range level {
		buf.Write([]byte("| "))
	}
	buf.WriteString(fmt.Sprintf("%s\n", node.move.String()))
	for _, child := range node.children {
		child.bytes(buf, level+1)
	}
}
