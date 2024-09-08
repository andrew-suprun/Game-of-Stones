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

func (g *testGame) PossibleMoves(limit int) []testMove {
	fmt.Println("PossibleMoves: limit =", limit)
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
		fmt.Println("PossibleMove: ", move)
		return []testMove{move}
	}

	result := make([]testMove, 0)
	for range 5 {
		g.id++
		move := testMove{
			id: g.id,
		}
		if g.rng.Intn(5) == 0 {
			move.score = 0
		} else {
			score := g.rng.Intn(201) - 100
			if g.maxer {
				if score > limit {
					move.score = score
					result = append(result, move)
				}
			} else {
				if score < limit {
					move.score = score
					result = append(result, move)
				}
			}
		}
	}
	fmt.Println("PossibleMoves: ", result)
	return result
}

type testMove struct {
	id    int
	score int
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

func (m testMove) Score() int {
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
		fmt.Println(t.root)
	}
	return t
}

func TestTree(t *testing.T) {
	tree := genTestTree(5, 0)
	fmt.Println("tree.root.children", len(tree.root.children))
	move, score := tree.root.bestMove(true)
	fmt.Println("best move", move, "score", score)

	t.Fail()
}
