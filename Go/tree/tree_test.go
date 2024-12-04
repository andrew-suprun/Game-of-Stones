package tree

import (
	"fmt"
	"math/rand"
	"testing"
)

var rnd = rand.New(rand.NewSource(3))

type testMove struct {
	id    int
	score int
	state GameState
}

func (m testMove) Score() int {
	return m.score
}

func (m testMove) State() GameState {
	return m.state
}

var id = 0

const maxScore = 5

func newMove() testMove {
	move := testMove{
		id:    id,
		score: rnd.Intn(maxScore*2+1) - maxScore,
		state: Inconclusive,
	}
	switch move.score {
	case 0:
		move.state = Draw
	case -5:
		move.state = MinnerWin
	case 5:
		move.state = MaxerWin
	}
	id++
	return move
}

type testGame struct {
	depth int
}

func (game *testGame) Turn() Player {
	if game.depth%2 == 0 {
		return Maxer
	}
	return Minner
}

func (game *testGame) PlayMove(move testMove) {
	fmt.Println(">>> PlayMove", move)
}

func (game *testGame) UndoMove(move testMove) {
	fmt.Println("<<< UndoMove", move)
}

func (game *testGame) PossibleMoves(result *[]testMove) {
	*result = (*result)[:0]
	nChildren := rnd.Intn(5) + 1
	for range nChildren {
		*result = append(*result, newMove())
	}
}

func (game *testGame) Less(a, b testMove) bool {
	return a.score < b.score
}

func TestFirstLeaf(t *testing.T) {
	game := &testGame{}
	tree := NewTree(game, 8)
	tree.grow()
	tree.grow()
	tree.grow()
	fmt.Printf("%v\n", tree)
}
