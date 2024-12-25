//go:build debug

package treeX

import "fmt"

func (tree *Tree[game, move]) validate() {
	tree.root.validate()
}

func (node *node[move]) validate() {
	if node.child != nil {
		if node.child.parent != node {
			panic(fmt.Sprintf("### PANIC.1: node: %v, child: %v", node.move, node.child.move))
		}
		if node.child.prev != nil {
			panic(fmt.Sprintf("### PANIC.2: node: %v, child: %v, child.prev: %v", node.move, node.child.move, node.child.prev.move))
		}
		child := node.child
		for child != nil {
			if child.next != nil {
				if child != child.next.prev {
					panic("### 3")
				}
			}
			child.validate()
			child = child.next
		}
	}
}
