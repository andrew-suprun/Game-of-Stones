package connect6

import (
	"fmt"
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
	if m.GoString() != "move(8, 8, 8, 9, 24)" {
		fmt.Printf("%#v\n", m)
		t.Fail()
	}
	if m.String() != "i11-i10" {
		fmt.Printf("%v\n", m)
		t.Fail()
	}
}

func TestPossibleMoves(t *testing.T) {
	c6 := NewGame()
	c6.MakeMove(9, 9, 9, 9)
	c6.MakeMove(8, 9, 8, 10)
	moves := make([]Move, 0, 20)
	c6.PossibleMoves(&moves)
	fmt.Println(c6.board.String())
	for i, m := range moves {
		fmt.Println(i+1, m, m.score)
	}
}
