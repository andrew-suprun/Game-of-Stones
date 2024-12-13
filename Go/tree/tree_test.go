package tree

import (
	"fmt"
	"game_of_stones/score"
	"math/rand"
	"testing"
)

const maxScore = 5

var rnd = rand.New(rand.NewSource(0))
var id = 0

type testMove struct {
	id    int
	score score.Score
}

func (m testMove) Score() score.Score {
	return m.score
}

func newMove() testMove {
	id++
	move := testMove{
		id:    id,
		score: score.Score(rnd.Intn(maxScore*2+1) - maxScore),
	}
	return move
}

func (m testMove) String() string {
	return fmt.Sprintf("(%v s:%v)", m.id, m.score)
}

type testGame struct{}

func (game *testGame) PlayMove(move testMove) {
}

func (game *testGame) UndoMove(move testMove) {
}

func (game *testGame) PossibleMoves(result *[]testMove) {
	*result = (*result)[:0]
	if rnd.Intn(4) == 0 {
		id++
		*result = append(*result, testMove{
			id:    id,
			score: 100_000,
		})
		return
	}
	nChildren := rnd.Intn(5) + 1
	for range nChildren {
		*result = append(*result, newMove())
	}
}

func (game *testGame) Less(a, b testMove) bool {
	return a.score < b.score
}

const expected = `(0 s:0)
|   (5 s:4)
|   |   (9 s:Draw)
|   |   (7 s:3)
|   |   |   (15 s:-4)
|   |   |   |   (25 s:Draw)
|   |   |   |   (24 s:-5)
|   |   |   |   |   (45 s:Draw)
|   |   |   |   |   (43 s:3)
|   |   |   |   |   |   (62 s:-4)
|   |   |   |   |   |   |   (78 s:3)
|   |   |   |   |   |   |   |   (102 s:2)
|   |   |   |   |   |   |   |   (101 s:-2)
|   |   |   |   |   |   |   |   (100 s:-5)
|   |   |   |   |   |   |   |   (99 s:4)
|   |   |   |   |   |   (61 s:-1)
|   |   |   |   |   |   |   (79 s:Draw)
|   |   |   |   |   |   (60 s:0)
|   |   |   |   |   |   |   (87 s:3)
|   |   |   |   |   |   |   |   (106 s:0)
|   |   |   |   |   |   |   |   (105 s:-5)
|   |   |   |   |   |   |   (85 s:Draw)
|   |   (6 s:Draw)
|   (2 s:3)
|   |   (13 s:4)
|   |   |   (18 s:Draw)
|   |   |   (17 s:Draw)
|   |   |   (16 s:5)
|   |   |   |   (31 s:-2)
|   |   |   |   |   (49 s:Draw)
|   |   |   |   |   (48 s:5)
|   |   |   |   |   |   (65 s:-1)
|   |   |   |   |   |   |   (89 s:5)
|   |   |   |   |   |   |   |   (109 s:-4)
|   |   |   |   |   |   |   |   (108 s:3)
|   |   |   |   |   (47 s:Draw)
|   |   |   |   (29 s:-2)
|   |   |   |   |   (52 s:4)
|   |   |   |   |   |   (70 s:0)
|   |   |   |   |   |   |   (94 s:Draw)
|   |   (12 s:0)
|   |   |   (21 s:Draw)
|   |   |   (20 s:3)
|   |   |   |   (34 s:-2)
|   |   |   |   |   (57 s:Draw)
|   (1 s:Draw)
`

func TestGrow(t *testing.T) {
	game := &testGame{}
	tree := NewTree(game, 8)
	for range 8 {
		tree.Grow()
	}
	fmt.Println(tree)
	if tree.String() != expected {
		t.Fail()
	}
}
