package tree

import (
	"fmt"
	"math/rand"
	"testing"
)

type testGame struct {
	id    int
	rng   *rand.Rand
	maxer bool
}

func newTestGame(seed int64) *testGame {
	return &testGame{
		rng:   rand.New(rand.NewSource(seed)),
		maxer: true,
	}
}

func (g *testGame) PlayMove(m testMove) {
	g.maxer = !g.maxer
}

func (g *testGame) UndoMove(m testMove) {
	g.maxer = !g.maxer
}

func (g *testGame) PossibleMoves() func() (testMove, bool) {
	children := 5
	return func() (testMove, bool) {
		if children == 0 {
			return testMove{}, false
		}
		if g.rng.Intn(5) == 0 {
			g.id++
			children = 0
			move := testMove{
				id: g.id,
			}
			if g.maxer {
				move.score = 1000
			} else {
				move.score = -1000
			}
			return move, true
		}

		children--
		g.id++
		return testMove{
			id:    g.id,
			score: int16(g.rng.Intn(201) - 100),
		}, true
	}
}

type testMove struct {
	id    int
	score int16
}

func (m testMove) String() string {
	state := ""
	if m.IsWin() {
		state = " win"
	} else if m.IsDraw() {
		state = " draw"
	}
	return fmt.Sprintf("<move %d score %d%s>", m.id, m.score, state)
}

func (m testMove) Score() int16 {
	return m.score
}

func (m testMove) IsDraw() bool {
	return m.score == 0
}

func (m testMove) IsWin() bool {
	return m.score == 1000 || m.score == -1000
}

func genTestTree(depth int, seed int64) *tree[testMove] {
	t := NewTree(newTestGame(seed), 8, maxLess[testMove], minLess[testMove])
	for range depth {
		t.Expand()
		t.root.Print()
	}
	return t
}

func TestTree(t *testing.T) {
	tree := genTestTree(5, 1)
	move, score := tree.root.bestMove(true)
	fmt.Println("best move", move, "score", score)
}
