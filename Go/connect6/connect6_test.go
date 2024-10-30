package connect6

import (
	"fmt"
	"game_of_stones/board"
	"math"
	"testing"
)

func TestGoString(t *testing.T) {
	result := fmt.Sprintf("%[1]v: %#[1]v", move(1, 2, 3, 4, 5))
	if result != "b17-d15: move(1, 2, 3, 4, 5)" {
		t.Fail()
	}
}

func TestMakeMove(t *testing.T) {
	c6 := NewGame()
	m := c6.MakeMove(8, 8, 8, 9)
	if m.GoString() != "move(8, 8, 8, 9, 48)" {
		fmt.Printf("%#v\n", m.GoString())
		t.FailNow()
	}
}

type place struct {
	x, y byte
}

func TestPossibleMoves(t *testing.T) {
	c6 := NewGame()
	c6.MakeMove(9, 9, 9, 9)
	c6.MakeMove(8, 9, 8, 10)
	moves := c6.PossibleMoves()

	fmt.Println(c6.board.String())
	nMoves := 0
	places := map[place]struct{}{}
	for {
		if move, ok := moves(math.MinInt16); ok {
			nMoves++
			places[place{move.X1, move.Y1}] = struct{}{}
			places[place{move.X2, move.Y2}] = struct{}{}
		} else {
			break
		}
	}
	if len(places) != board.Size*board.Size-3 || nMoves != 63903 {
		t.FailNow()
	}
}
