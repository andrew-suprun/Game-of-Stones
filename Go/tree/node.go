package tree

import (
	"bytes"
	"fmt"
	"math"
)

type node[move iMove] struct {
	parent   *node[move]
	children map[move]*node[move]
	move     move
	draw     bool
}

func (n *node[pMove]) addMove(move pMove) *node[pMove] {
	child := &node[pMove]{parent: n, children: map[pMove]*node[pMove]{}, move: move, draw: move.Draws()}
	n.children[move] = child
	fmt.Println("added", move, "to", n.move)
	return child
}

func maxLess[move iMove](a, b *node[move]) bool {
	return a.move.Score() < b.move.Score()
}

func minLess[move iMove](a, b *node[move]) bool {
	return a.move.Score() > b.move.Score()
}

func (node *node[move]) bestMove(maxer bool) (move, int) {
	var bestMove move
	if maxer {
		bestScore := math.MinInt
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestMove = child.move
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	} else {
		bestScore := math.MaxInt
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

func (node *node[_]) bestScore(maxer bool) int {
	if len(node.children) == 0 {
		return node.move.Score()
	}

	if maxer {
		bestScore := math.MinInt
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestScore = childScore
			}
		}
		return bestScore
	} else {
		bestScore := math.MaxInt
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore > childScore {
				bestScore = childScore
			}
		}
		return bestScore
	}
}

func (node *node[_]) String() string {
	return string(node.Bytes())
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
