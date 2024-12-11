package tree

import (
	"fmt"
	"math/rand"
	"testing"
)

const maxScore = 5

var rnd = rand.New(rand.NewSource(0))
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

func (s testScore) String() string {
	if s.isDraw {
		return "D"
	}
	if s.isWin {
		return "W"
	}
	return fmt.Sprintf("s:%d", s.score)
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
	if move.score.score == 0 {
		move.score.isDraw = true
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
	return fmt.Sprintf("(%v %v)", m.id, m.score)
}

type testGame struct {
	depth    int
	lastMove testMove
}

func (game *testGame) PlayMove(move testMove) {
	game.lastMove = move
}

func (game *testGame) UndoMove(move testMove) {
}

func (game *testGame) PossibleMoves(result *[]testMove) {
	*result = (*result)[:0]
	if rnd.Intn(4) == 0 {
		id++
		*result = append(*result, testMove{
			id: id,
			score: testScore{
				score: maxScore + 1,
				isWin: true,
			},
		})
		return
	}
	nChildren := rnd.Intn(5) + 1
	for range nChildren {
		*result = append(*result, newMove())
	}
}

func (game *testGame) Less(a, b testMove) bool {
	return a.score.score < b.score.score
}

const expected = `(0 s:0)
|   (5 s:4)
|   |   (8 s:2)
|   |   |   (17 s:1)
|   |   |   |   (35 s:-2)
|   |   |   |   |   (52 s:4)
|   |   |   |   |   |   (73 D)
|   |   |   |   |   |   (72 D)
|   |   |   |   |   |   (71 s:2)
|   |   |   |   |   |   |   (92 D)
|   |   |   |   |   |   |   (90 s:-2)
|   |   |   |   |   |   |   |   (109 s:-4)
|   |   |   |   |   |   (70 D)
|   |   (7 s:3)
|   |   |   (21 s:1)
|   |   |   |   (40 s:-5)
|   |   |   |   |   (56 D)
|   |   |   (20 s:3)
|   |   |   |   (41 s:-3)
|   |   |   |   |   (60 D)
|   (2 s:3)
|   |   (13 s:4)
|   |   |   (27 s:5)
|   |   |   |   (42 s:-5)
|   |   |   |   |   (66 s:3)
|   |   |   |   |   |   (82 s:2)
|   |   |   |   |   |   |   (95 s:2)
|   |   |   |   |   |   |   |   (117 D)
|   |   |   |   |   |   |   |   (116 s:1)
|   |   |   |   |   |   |   |   (115 s:-4)
|   |   |   |   |   |   |   |   (114 s:1)
|   |   |   |   |   |   (81 s:-1)
|   |   |   |   |   |   |   (102 s:2)
|   |   |   |   |   |   |   |   (122 s:1)
|   |   |   |   |   |   |   |   (121 s:-2)
|   |   |   |   |   |   |   |   (120 s:-1)
|   |   |   |   |   |   |   (101 s:-2)
|   |   |   |   |   |   |   |   (125 s:-4)
|   |   |   (26 s:-2)
|   |   |   |   (50 s:-5)
|   |   |   |   |   (68 s:3)
|   |   |   |   |   |   (85 s:1)
|   |   |   |   |   |   |   (106 D)
|   |   (12 D)
`

func TestFirstLeaf(t *testing.T) {
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
