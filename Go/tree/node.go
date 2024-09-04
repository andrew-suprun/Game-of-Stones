package tree

import (
	"bytes"
	"fmt"
	"math"
)

type Node[move Move] struct {
	parent   *Node[move]
	children map[move]*Node[move]
	move     move
}

func (node *Node[move]) AddMove(m move) *Node[move] {
	child := &Node[move]{parent: node}
	if node.children == nil {
		node.children = map[move]*Node[move]{m: child}
	} else {
		node.children[m] = child
	}
	return child
}

func (node *Node[Move]) Remove() {
	delete(node.parent.children, node.move)
	if len(node.parent.children) == 0 && node.parent.parent != nil {
		delete(node.parent.parent.children, node.parent.move)
		if node.parent.parent.parent != nil {
			node.parent.parent.Remove()
		}
	}
}

func (node *Node[move]) BestChild(player Player) (move, int) {
	// if len(node.children) == 0 {
	// 	return node.move, node.move.Score()
	// }

	if player == firstPlayer {
		var bestMove move
		bestScore := math.MaxInt
		for _, child := range node.children {
			childMove, childScore := child.BestChild(secondPlayer)
			if bestScore < childScore {
				bestMove = childMove
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	} else {
		var bestMove move
		bestScore := math.MinInt
		for _, child := range node.children {
			childMove, childScore := child.BestChild(firstPlayer)
			if bestScore > childScore {
				bestMove = childMove
				bestScore = childScore
			}
		}
		return bestMove, bestScore
	}
}

func (node *Node[Move]) String() string {
	return string(node.Bytes())
}

func (node *Node[Move]) Bytes() []byte {
	buf := &bytes.Buffer{}
	node.bytes(buf, 0)
	return buf.Bytes()
}

func (node *Node[Move]) bytes(buf *bytes.Buffer, level int) {
	for range level {
		buf.Write([]byte("| "))
	}
	buf.WriteString(fmt.Sprintf("%s\n", node.move.String()))
	for _, child := range node.children {
		child.bytes(buf, level+1)
	}
}
