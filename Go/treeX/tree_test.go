package treeX

import (
	"fmt"
	"game_of_stones/value"
	"math/rand"
)

const maxValue = 5

var rnd = rand.New(rand.NewSource(0))
var id = 0

type testMove struct {
	id    int
	value value.Value
}

func (m testMove) Value() value.Value {
	return m.value
}

func newMove() testMove {
	id++
	move := testMove{
		id:    id,
		value: value.Value(rnd.Intn(maxValue*2+1) - maxValue),
	}
	return move
}

func (game *testGame) ParseMove(moveStr string) (testMove, error) {
	return testMove{}, nil
}

func (game *testGame) SameMove(a, b testMove) bool {
	return a.id == b.id
}

func (m testMove) String() string {
	return fmt.Sprintf("(%v s:%v)", m.id, m.value)
}

type testGame struct{}

func (game *testGame) PlayMove(move testMove) {
}

func (game *testGame) UndoMove(move testMove) {
}

func (game *testGame) TopMoves(result *[]testMove) {
	*result = (*result)[:0]
	if rnd.Intn(4) == 0 {
		id++
		*result = append(*result, testMove{
			id:    id,
			value: 100_000,
		})
		return
	}
	nChildren := rnd.Intn(5) + 1
	for range nChildren {
		*result = append(*result, newMove())
	}
}

func (game *testGame) Less(a, b testMove) bool {
	return a.value < b.value
}
