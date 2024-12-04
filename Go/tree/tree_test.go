package tree

import (
	"fmt"
	"math/rand"
	"testing"
)

const maxScore = 5

var rnd = rand.New(rand.NewSource(3))
var id = 0

type testMove struct {
	id     int
	score  int
	isDraw bool
	isWin  bool
}

func newMove() testMove {
	move := testMove{
		id:    id,
		score: rnd.Intn(maxScore*2+1) - maxScore,
	}
	switch move.score {
	case 0:
		move.isDraw = true
	case 5, -5:
		move.isWin = true
	}
	id++
	return move
}

func (m testMove) IsWin() bool {
	return m.isWin
}

func (m testMove) IsDraw() bool {
	return m.isDraw
}

func (m testMove) String() string {
	if m.isDraw {
		return fmt.Sprintf("%v: score Draw", m.id)
	}
	if m.isWin {
		return fmt.Sprintf("%v: score Win", m.id)
	}
	return fmt.Sprintf("%v: score %v", m.id, m.score)
}

type testGame struct {
	depth int
}

func (game *testGame) PlayMove(move testMove) {
}

func (game *testGame) UndoMove(move testMove) {
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
