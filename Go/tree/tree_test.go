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
	fmt.Println(">>> game.PlayMove", move)
	game.state = move
}

func (game *testGame) UndoMove(move testMove) {
	fmt.Println("<<< game.UndoMove", move)
	switch game.state {
	case 1, 2, 3:
		game.state = 0
	case 4, 5:
		game.state = 1
	case 6, 7, 8:
		game.state = 2
	case 9, 10:
		game.state = 3
	case 11, 12:
		game.state = 4
	case 13, 14:
		game.state = 5
	case 15:
		game.state = 6
	case 16, 17, 18:
		game.state = 8
	case 19:
		game.state = 9
	case 20:
		game.state = 10
	}
}

func (game *testGame) PossibleMoves(result *[]testMove) GameState {
	*result = (*result)[:0]
	switch game.state {
	case 0:
		(*result) = []testMove{1, 2, 3}
	case 1:
		(*result) = []testMove{4, 5}
	case 2:
		(*result) = []testMove{6, 7, 8}
	case 3:
		(*result) = []testMove{9, 10}
	case 4:
		(*result) = []testMove{11, 12}
	case 5:
		(*result) = []testMove{13, 14}
	case 6:
		(*result) = []testMove{15}
	case 7:
		(*result) = []testMove{}
	case 8:
		(*result) = []testMove{16, 17, 18}
	case 9:
		(*result) = []testMove{19}
	case 10:
		(*result) = []testMove{20}
	}
	if len(*result) == 0 {
		return Draw
	}
	return Inconclusive
}

func (game *testGame) Less(a, b testMove) bool {
	return a < b
}

const strTree = `0
|   3
|   |   10
|   |   |   20
|   |   9
|   |   |   19
|   2
|   |   8
|   |   |   18
|   |   |   17
|   |   |   16
|   |   7
|   |   6
|   |   |   15
|   1
|   |   5
|   |   |   14
|   |   |   13
|   |   4
|   |   |   12
|   |   |   11
`

func TestFirstLeaf(t *testing.T) {
	game := &testGame{}
	tree := NewTree(game, 8)
	for i := range 13 {
		tree.Expand()
		fmt.Printf("--- current.%d: move %v cur %v max %v tree:\n%#v\n", i, tree.current.move, tree.curDepth, tree.maxDepth, tree)
	}
	if tree.GoString() != strTree {
		t.Fail()
	}
}
