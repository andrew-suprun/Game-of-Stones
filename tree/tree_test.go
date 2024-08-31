package tree

import (
	"fmt"
	"testing"
)

type move int

func (m move) String() string {
	return fmt.Sprintf("move %d", m)
}

func TestNodeRemval(t *testing.T) {
	root := NewNode(move(-1))
	nodes := make([]*Node[move], 0)
	for i := range 12 {
		nodes = append(nodes, NewNode(move(i)))
	}
	root.AddChild(nodes[0])
	nodes[0].AddChild(nodes[1])
	nodes[1].AddChild(nodes[2])
	nodes[2].AddChild(nodes[3])
	nodes[2].AddChild(nodes[4])
	nodes[1].AddChild(nodes[5])
	nodes[5].AddChild(nodes[6])
	nodes[5].AddChild(nodes[7])
	root.AddChild(nodes[8])
	nodes[8].AddChild(nodes[9])
	nodes[9].AddChild(nodes[10])

	fmt.Println(root.String())
	nodes[9].RemoveChild(nodes[10].move)
	fmt.Println(root.String())
	if len(root.children) != 1 {
		fmt.Println("root children", len(root.children))
		t.Fail()
	}

	nodes[5].Remove()
	fmt.Println(root.String())
	if len(nodes[1].children) != 1 {
		fmt.Println("node.1 children", len(nodes[1].children))
		t.Fail()
	}

	nodes[2].RemoveChild(nodes[3].move)
	fmt.Println(root.String())
	if len(nodes[2].children) != 1 {
		fmt.Println("node.2 children", len(nodes[2].children))
		t.Fail()
	}
}
