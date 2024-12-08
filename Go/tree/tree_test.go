package tree

import (
	"fmt"
	"math/rand"
	"testing"
)

const maxScore = 5

var rnd = rand.New(rand.NewSource(3))
var id = 0

type testScore struct {
	score  int
	isDraw bool
	isWin  bool
}

func (s testScore) IsWinning() bool {
	return s.isWin
}

func (s testScore) IsDrawing() bool {
	return s.isDraw
}

type testMove struct {
	id    int
	score testScore
}

func (m testMove) Score() testScore {
	return m.score
}

func newMove() testMove {
	id++
	move := testMove{
		id:    id,
		score: testScore{score: rnd.Intn(maxScore*2+1) - maxScore},
	}
	switch move.score.score {
	case 0:
		move.score.isDraw = true
	case 5, -5:
		move.score.isWin = true
	}
	return move
}

func (m testMove) IsWinning() bool {
	return m.score.isWin
}

func (m testMove) IsDrawing() bool {
	return m.score.isDraw
}

func (m testMove) String() string {
	return fmt.Sprintf("%v: score %v", m.id, m.score)
}

type testGame struct {
	depth int
}

func (game *testGame) PlayMove(move testMove) {
	fmt.Println(">>> play", move.id)
}

func (game *testGame) UndoMove(move testMove) {
	fmt.Println("<<< undo", move.id)
}

func (game *testGame) PossibleMoves(result *[]testMove) {
	*result = (*result)[:0]
	nChildren := rnd.Intn(5) + 1
	for range nChildren {
		*result = append(*result, newMove())
	}
}

func (game *testGame) Less(a, b testMove) bool {
	return a.score.score < b.score.score
}

func TestFirstLeaf(t *testing.T) {
	game := &testGame{}
	tree := NewTree(game, 8)
	tree.Grow()
	tree.Grow()
	tree.Grow()
	tree.Grow()
	tree.Grow()
	fmt.Println(tree)
}
