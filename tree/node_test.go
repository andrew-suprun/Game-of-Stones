package tree

import (
	"fmt"
	"testing"
)

type move int

func (m move) String() string {
	return fmt.Sprintf("move %d", m)
}

func (m move) Score() int {
	return int(m)
}

func TestNodeRemval(t *testing.T) {
	root := &Node[move]{move: -1}
	node0 := root.AddMove(0)
	node1 := node0.AddMove(1)
	node2 := node1.AddMove(2)
	node2.AddMove(3)
	node2.AddMove(4)
	node5 := node1.AddMove(5)
	node6 := node5.AddMove(6)
	node7 := node5.AddMove(7)
	node8 := root.AddMove(8)
	node9 := node8.AddMove(9)
	node10 := node9.AddMove(10)

	fmt.Println(root.String())
	node10.Remove()
	fmt.Println(root.String())
	if len(root.children) != 1 {
		fmt.Println("root children", len(root.children))
		t.Fail()
	}

	node6.Remove()
	fmt.Println(root.String())
	if len(node5.children) != 1 {
		fmt.Println("node5 children", len(node5.children))
		t.Fail()
	}
	root.AddMove(11)
	fmt.Println(root.String())

	node7.Remove()
	fmt.Println(root.String())
	if len(root.children) != 1 {
		fmt.Println("root children", len(root.children))
		t.Fail()
	}
}
