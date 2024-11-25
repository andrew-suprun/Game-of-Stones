package tree

import (
	"fmt"
	"testing"
)

type testMove int

func (m testMove) State() GameState {
	return Inconclusive
}

type testGame struct {
	state testMove
}

func (game *testGame) Turn() Player {
	return Maxer
}

func (game *testGame) PlayMove(move testMove) {
	fmt.Println("game.PlayMove", move)
	game.state = move
}

func (game *testGame) UndoMove(move testMove) {
	fmt.Println("game.UndoMove", move)
	switch game.state {
	case 1, 2, 3:
		game.state = 0
	}
}

func (game *testGame) PossibleMoves(result *[]testMove) GameState {
	switch game.state {
	case 0:
		(*result) = []testMove{1, 2, 3}
	}
	return Inconclusive
}

func (game *testGame) Less(a, b testMove) bool {
	return a < b
}

func TestFirstLeaf(t *testing.T) {
	game := &testGame{}
	tree := NewTree(game, 8)
	n1 := &node[testMove]{move: 1}
	tree.root.child = n1
	n1.parent = tree.root
	tree.findLeaf(true)
	fmt.Printf("%v\n", tree)
}
