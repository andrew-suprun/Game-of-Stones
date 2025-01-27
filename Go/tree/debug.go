//go:build debug

package tree

import (
	"log"

	. "game_of_stones/common"
)

func (tree *Tree[move]) validate() {
	tree.root.validate(tree.game.Turn())
}

func (node *node[move]) validate(turn Turn) {
	if len(node.children) == 0 {
		// if node.move.IsDecisive() && !node.move.IsTerminal() {
		// 	log.Panicf("### Validation ### decisive childless node")
		// }
		return
	}
	expected := node.children[0].value
	if turn == First {
		for _, child := range node.children {
			expected = max(expected, child.value)
			child.validate(Second)
		}
	} else {
		for _, child := range node.children {
			expected = min(expected, child.value)
			child.validate(First)
		}
	}
	if expected != node.value {
		log.Panicf("### Validation ### move: %#v expected %v", node.move, expected)
	}
}
