package connect6

import (
	"fmt"
	"testing"
)

func TestGoString(t *testing.T) {
	result := fmt.Sprintf("%[1]v: %#[1]v", MakeMove(1, 2, 3, 4))
	if result != "b17-d15: move(1, 2, 3, 4)" {
		t.Fail()
	}
}

func TestPossibleMoves(t *testing.T) {
	c6 := NewGame()
	originalBoard := c6.board
	c6.PlayMove(MakeMove(8, 9, 9, 8))
	moves := make([]Move, 0, 1)

	played := []Move{}

	nMoves := 3

	for range nMoves {
		c6.PossibleMoves(&moves)
		fmt.Println(moves)
		c6.PlayMove(moves[0])
		fmt.Println(&c6.board)
		played = append(played, moves[0])
	}
	for i := range nMoves {
		c6.UndoMove(played[nMoves-1-i])
	}

	c6.UndoMove(MakeMove(8, 9, 9, 8))

	if originalBoard != c6.board {
		t.Fail()
	}
}
