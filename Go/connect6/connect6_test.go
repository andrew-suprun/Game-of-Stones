package connect6

import (
	"fmt"
	"game_of_stones/board"
	"math"
	"testing"
)

func TestGoString(t *testing.T) {
	result := fmt.Sprintf("%[1]v: %#[1]v", makeMove(1, 2, 3, 4, 5))
	if result != "b17-d15: makeMove(1, 2, 3, 4, 5)" {
		t.Fail()
	}
}

func TestMakeMove(t *testing.T) {
	c6 := NewGame(8)
	m, err := c6.MakeMove("i10-i11")
	if m.GoString() != "makeMove(8, 8, 8, 9, 126)" || err != nil {
		t.FailNow()
	}
}

type place struct {
	x, y byte
}

func TestPossibleMoves(t *testing.T) {
	c6 := NewGame(8)
	move, _ := c6.MakeMove("j10-j10")
	c6.PlayMove(move)
	move, _ = c6.MakeMove("i9-i10")
	c6.PlayMove(move)
	moves := c6.PossibleMoves()

	fmt.Println(c6.board.String())
	nMoves := 0
	places := map[place]struct{}{}
	for {
		if move, ok := moves(math.MinInt16); ok {
			nMoves++
			places[place{move.x1, move.y1}] = struct{}{}
			places[place{move.x2, move.y2}] = struct{}{}
		} else {
			break
		}
	}
	if len(places) != board.Size*board.Size-3 || nMoves != 63903 {
		t.FailNow()
	}
}
