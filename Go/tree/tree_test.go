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

func (g *testGame) MakeMove(m testMove) {
	g.maxer = !g.maxer
}

func (g *testGame) UnmakeMove(m testMove) {
	g.maxer = !g.maxer
}

func (g *testGame) PossibleMoves(limit int32) []testMove {
	r := g.rng.Intn(5)
	if r == 0 {
		g.id++
		move := testMove{
			id: g.id,
		}
		if g.maxer {
			move.score = 1000
		} else {
			move.score = -1000
		}
		return []testMove{move}
	}

	result := make([]testMove, 0)
	for range 5 {
		var score int32 = 0
		if g.rng.Intn(5) > 0 {
			score = int32(g.rng.Intn(201) - 100)
		}
		if g.maxer {
			if score > limit {
				g.id++
				result = append(result, testMove{
					id:    g.id,
					score: score,
				})
			}
		} else {
			if score < limit {
				g.id++
				result = append(result, testMove{
					id:    g.id,
					score: score,
				})
			}
		}
	}
	return result
}

type testMove struct {
	id    int
	score int32
}

func (m testMove) String() string {
	state := ""
	if m.Wins() {
		state = " win"
	} else if m.Draws() {
		state = " draw"
	}
	return fmt.Sprintf("<move %d score %d%s>", m.id, m.score, state)
}

func (m testMove) Score() int32 {
	return m.score
}

func (m testMove) Draws() bool {
	return m.score == 0
}

func (m testMove) Wins() bool {
	return m.score == 1000 || m.score == -1000
}

func gInit() *testGame {
	return &testGame{}
}

func genTestTree(depth int, seed int64) *tree[*testGame, testMove] {
	t := newTree(gInit, 8, maxLess[testMove], minLess[testMove])
	testGame := newTestGame(seed)
	for range depth {
		t.expand(testGame)
		t.root.Print()
	}
	return t
}

func TestTree(t *testing.T) {
	tree := genTestTree(5, 0)
	move, score := tree.root.bestMove(true)
	fmt.Println("best move", move, "score", score)

	t.Fail()
}
