//go:build debug

package tree

import (
	"log"

	. "game_of_stones/turn"
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
	expected := node.children[0].move.Value()
	if turn == First {
		for _, child := range node.children {
			expected = max(expected, child.move.Value())
			child.validate(Second)
		}
	} else {
		for _, child := range node.children {
			expected = min(expected, child.move.Value())
			child.validate(First)
		}
	}
	if expected != node.move.Value() {
		log.Panicf("### Validation ### move: %#v expected %v", node.move, expected)
	}
}
