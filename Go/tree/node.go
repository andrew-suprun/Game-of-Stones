package tree

import (
	"bytes"
	"fmt"
	"math"
)

type node[move iMove] struct {
	parent   *node[move]
	selfIdx  uint16
	children []node[move]
	move     move
	draw     bool
}

func (n *node[pMove]) addMove(move pMove) {
	child := node[pMove]{parent: n, selfIdx: uint16(len(n.children)), move: move, draw: move.Draws()}
	fmt.Println("addMove: move", move)
	n.children = append(n.children, child)
}

func (n *node[move]) less(other *node[move]) bool {
	return n.move.Score() < other.move.Score()
}

func (node *node[move]) bestMove(maxer bool) (move, int) {
	var bestMove move
	if maxer {
		bestScore := math.MaxInt
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore > childScore {
				bestMove = child.move
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	} else {
		bestScore := math.MinInt
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestMove = child.move
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	}
}

func (node *node[move]) bestScore(maxer bool) int {
	fmt.Println(">>bestChild: move", node.move, "children", len(node.children))
	if len(node.children) == 0 {
		fmt.Println("<< bestChild: move.1", node.move, "best child", node.move, "score", node.move.Score())
		return node.move.Score()
	}

	if maxer {
		bestScore := math.MaxInt
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore > childScore {
				bestScore = childScore
			}
		}
		fmt.Println("<< bestChild: move.2", node.move, "score", bestScore)
		return bestScore
	} else {
		bestScore := math.MinInt
		for _, child := range node.children {
			childScore := child.bestScore(!maxer)
			if bestScore < childScore {
				bestScore = childScore
			}
		}
		fmt.Println("<< bestChild: move.3", node.move, "score", bestScore)
		return bestScore
	}
}

func (node *node[Move]) String() string {
	return string(node.Bytes())
}

func (node *node[Move]) Bytes() []byte {
	buf := &bytes.Buffer{}
	node.bytes(buf, 0)
	return buf.Bytes()
}

func (node *node[Move]) bytes(buf *bytes.Buffer, level int) {
	for range level {
		buf.Write([]byte("| "))
	}
	buf.WriteString(fmt.Sprintf("%s\n", node.move.String()))
	for _, child := range node.children {
		child.bytes(buf, level+1)
	}
}
