//go:build debug

package tree

import (
	"log"

	. "game_of_stones/common"
)

func (tree *Tree[move]) validate() {
	tree.validateNode(0, tree.game.Turn())
}

func (tree *Tree[move]) validateNode(idx int32, turn Turn) {
	node := tree.nodes[idx]
	if node.firstChild == 0 {
		return
	}
	expected := tree.nodes[node.firstChild].value
	if turn == First {
		for childIdx := node.firstChild; childIdx < node.lastChild; childIdx++ {
			child := tree.nodes[childIdx]
			expected = max(expected, child.value)
			tree.validateNode(childIdx, Second)
		}
	} else {
		for childIdx := node.firstChild; childIdx < node.lastChild; childIdx++ {
			child := tree.nodes[childIdx]
			expected = min(expected, child.value)
			tree.validateNode(childIdx, First)
		}
	}
	if expected != node.value {
		log.Panicf("### Validation ### move: %#v expected %v", tree.moves[idx], expected)
	}
}
