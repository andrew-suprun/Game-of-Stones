package tree

import (
	"fmt"
	"testing"
)

type testGame struct{}

func (g *testGame) PossibleMoves([]testMove) []testMove {
	return []testMove{}
}

type testMove int

func (m testMove) String() string {
	return fmt.Sprintf("move %d", m)
}

func (m testMove) Score() int {
	return int(m)
}

type node struct {
	children map[testMove]node
}

func genTree(source map[testMove]node) map[testMove]*Node[testMove] {
	result := map[testMove]*Node[testMove]{}
	for m, n := range source {
		result[m] = genNode(n)
	}
	return result
}

func genNode(n node) *Node[testMove] {
	result := &Node[testMove]{children: genTree(n.children)}
	for _, n := range result.children {
		n.parent = n
	}
	return result
}

func TestTree(t *testing.T) {
	source := map[testMove]node{
		1: {
			map[testMove]node{
				3: {},
				4: {},
			},
		},
		2: {
			map[testMove]node{
				5: {},
				6: {},
			},
		},
	}
	root := Tree[*testGame, testMove]{
		root: genTree(source),
	}
	fmt.Printf("%v\n", root)
}
