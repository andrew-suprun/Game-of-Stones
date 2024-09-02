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

func TestBestChild(t *testing.T) {
	tree := Tree[*testGame, testMove]{
		root: &Node[testMove]{},
	}
	_ = tree
}
