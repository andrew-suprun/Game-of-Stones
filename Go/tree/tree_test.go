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

func (g *testGame) PossibleMoves() []testMove {
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
		fmt.Println("move", move)
		return []testMove{move}
	}

	result := make([]testMove, g.rng.Intn(5)+1)
	for i := range result {
		g.id++
		move := testMove{
			id: g.id,
		}
		if g.rng.Intn(5) == 0 {
			move.score = 0
		} else {
			move.score = g.rng.Intn(201) - 100
		}
		result[i] = move
	}
	fmt.Println("moves", result)
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
	t := newTree(gInit, 20, (*node[testMove]).less)
	testGame := newTestGame(seed)
	for d := range depth {
		fmt.Println("expand depth", d)
		t.expand(t.root, testGame)
		fmt.Println(t.root)
	}
	return t
}

func TestTree(t *testing.T) {
	tree := genTestTree(4, 2)
	fmt.Println("tree.root.children", len(tree.root.children))
	move, score := tree.root.bestMove(true)
	fmt.Println("best move", move, "score", score)

	t.Fail()
}
