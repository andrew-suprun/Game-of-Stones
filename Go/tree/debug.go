//go:build debug

package tree

import (
	"log"
)

func (tree *Tree[game, move, value]) validate() {
	tree.root.validate(tree.game.Turn())
}

func (node *node[move, value]) validate(turn Turn) {
	if len(node.children) == 0 {
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
		log.Fatalf("### Validation ### move: %#v expected %v", node.move, expected)
	}
}
